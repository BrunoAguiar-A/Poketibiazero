#include "fileloader.h"
#include "itemloader.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <map>
#include <optional>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

#include <zlib.h>

namespace {

constexpr uint8_t NODE_ESCAPE = 0xFD;
constexpr uint8_t NODE_START = 0xFE;
constexpr uint8_t NODE_END = 0xFF;

constexpr uint8_t OTBM_MAP_DATA = 2;
constexpr uint8_t OTBM_TILE_AREA = 4;
constexpr uint8_t OTBM_TILE = 5;
constexpr uint8_t OTBM_ITEM = 6;
constexpr uint8_t OTBM_HOUSETILE = 14;

constexpr uint8_t OTBM_ATTR_TILE_FLAGS = 3;
constexpr uint8_t OTBM_ATTR_ITEM = 9;

constexpr uint32_t OTMM_SIGNATURE = 0x4D4D544F;
constexpr uint16_t OTMM_VERSION = 1;
constexpr uint8_t MAX_Z = 15;
constexpr uint32_t BLOCK_SIZE = 64;
constexpr uint32_t BLOCKS_PER_AXIS = 65536 / BLOCK_SIZE;
constexpr uint8_t MINIMAP_TILE_WAS_SEEN = 1;
constexpr uint8_t MINIMAP_TILE_NOT_PATHABLE = 2;
constexpr uint8_t MINIMAP_TILE_NOT_WALKABLE = 4;

#pragma pack(push, 1)
struct MinimapTile {
    uint8_t flags = 0;
    uint8_t color = 255;
    uint8_t speed = 10;
};
#pragma pack(pop)

struct ItemInfo {
    bool isGround = false;
    bool alwaysOnTop = false;
    bool blockSolid = false;
    bool blockPathFind = false;
    uint8_t alwaysOnTopOrder = 0;
    uint8_t minimapColor = 0;
    uint16_t groundSpeed = 0;
};

struct AreaContext {
    uint16_t x = 0;
    uint16_t y = 0;
    uint8_t z = 0;
};

struct TileContext {
    uint16_t x = 0;
    uint16_t y = 0;
    uint8_t z = 0;
    std::vector<uint16_t> topLevelItems;
};

struct NodeState {
    uint8_t type = 0;
    bool collectingProps = false;
    bool propsFinalized = false;
    std::vector<uint8_t> props;
    std::optional<AreaContext> area;
    std::optional<TileContext> tile;
    uint16_t itemServerId = 0;
};

struct BlockData {
    std::array<MinimapTile, BLOCK_SIZE * BLOCK_SIZE> tiles{};
    bool hasSeenTile = false;
};

class Cursor {
public:
    explicit Cursor(const std::vector<uint8_t>& data) : data(data) {}

    bool canRead(size_t count) const {
        return offset + count <= data.size();
    }

    bool empty() const {
        return offset >= data.size();
    }

    uint8_t readU8() {
        require(1);
        return data[offset++];
    }

    uint16_t readU16() {
        require(2);
        uint16_t value = data[offset] | (static_cast<uint16_t>(data[offset + 1]) << 8);
        offset += 2;
        return value;
    }

    uint32_t readU32() {
        require(4);
        uint32_t value = data[offset]
            | (static_cast<uint32_t>(data[offset + 1]) << 8)
            | (static_cast<uint32_t>(data[offset + 2]) << 16)
            | (static_cast<uint32_t>(data[offset + 3]) << 24);
        offset += 4;
        return value;
    }

private:
    void require(size_t count) const {
        if (!canRead(count)) {
            throw std::runtime_error("Unexpected end of property stream.");
        }
    }

    const std::vector<uint8_t>& data;
    size_t offset = 0;
};

using BlockMap = std::map<uint32_t, BlockData>;

uint16_t remapServerId(uint16_t serverId)
{
    if (serverId > 30000 && serverId < 30100) {
        return static_cast<uint16_t>(serverId - 30000);
    }
    return serverId;
}

int classifyPriority(const ItemInfo& item)
{
    if (item.isGround) {
        return 0;
    }

    if (!item.alwaysOnTop) {
        return 5;
    }

    if (item.alwaysOnTopOrder == 1) {
        return 1;
    }

    if (item.alwaysOnTopOrder == 2) {
        return 2;
    }

    return 3;
}

uint32_t makeBlockIndex(uint16_t x, uint16_t y)
{
    return (static_cast<uint32_t>(y / BLOCK_SIZE) * BLOCKS_PER_AXIS) + (x / BLOCK_SIZE);
}

MinimapTile buildTile(const TileContext& tile, const std::unordered_map<uint16_t, ItemInfo>& itemInfoByServerId)
{
    MinimapTile result;
    result.flags = MINIMAP_TILE_WAS_SEEN;

    std::array<std::vector<uint16_t>, 4> minimapPriorityIds;
    uint16_t groundSpeed = 100;

    for (uint16_t serverId : tile.topLevelItems) {
        auto it = itemInfoByServerId.find(serverId);
        if (it == itemInfoByServerId.end()) {
            continue;
        }

        const ItemInfo& item = it->second;

        if (item.isGround) {
            groundSpeed = item.groundSpeed != 0 ? item.groundSpeed : groundSpeed;
        }

        if (item.blockSolid) {
            result.flags |= MINIMAP_TILE_NOT_WALKABLE;
        }

        if (item.blockPathFind) {
            result.flags |= MINIMAP_TILE_NOT_PATHABLE;
        }

        int priority = classifyPriority(item);
        if (priority >= 0 && priority <= 3) {
            minimapPriorityIds[priority].push_back(serverId);
        }
    }

    for (const auto& ids : minimapPriorityIds) {
        for (uint16_t serverId : ids) {
            auto it = itemInfoByServerId.find(serverId);
            if (it == itemInfoByServerId.end()) {
                continue;
            }

            if (it->second.minimapColor != 0) {
                result.color = it->second.minimapColor;
            }
        }
    }

    result.speed = static_cast<uint8_t>(std::clamp<int>(static_cast<int>(std::ceil(groundSpeed / 10.0f)), 1, 255));
    return result;
}

void setTile(BlockMap blocksByFloor[static_cast<size_t>(MAX_Z) + 1], const TileContext& tile, const MinimapTile& minimapTile)
{
    if (tile.z > MAX_Z) {
        return;
    }

    const uint32_t blockIndex = makeBlockIndex(tile.x, tile.y);
    BlockData& block = blocksByFloor[tile.z][blockIndex];
    block.hasSeenTile = true;

    const uint32_t offsetX = tile.x % BLOCK_SIZE;
    const uint32_t offsetY = tile.y % BLOCK_SIZE;
    block.tiles[(offsetY * BLOCK_SIZE) + offsetX] = minimapTile;
}

std::unordered_map<uint16_t, ItemInfo> loadItemInfo(const std::string& itemsPath)
{
    OTB::Loader loader(itemsPath, OTB::Identifier{{'O', 'T', 'B', 'I'}});
    const OTB::Node& root = loader.parseTree();

    std::unordered_map<uint16_t, ItemInfo> itemInfoByServerId;
    itemInfoByServerId.reserve(root.children.size());

    for (const auto& itemNode : root.children) {
        PropStream stream;
        if (!loader.getProps(itemNode, stream)) {
            continue;
        }

        uint32_t flags = 0;
        if (!stream.read<uint32_t>(flags)) {
            continue;
        }

        uint16_t serverId = 0;
        uint16_t speed = 0;
        uint16_t minimapColor = 0;
        uint8_t topOrder = 0;

        uint8_t attribute = 0;
        while (stream.read<uint8_t>(attribute)) {
            uint16_t dataLength = 0;
            if (!stream.read<uint16_t>(dataLength)) {
                throw std::runtime_error("Invalid items.otb attribute length.");
            }

            switch (attribute) {
                case ITEM_ATTR_SERVERID: {
                    if (dataLength != sizeof(uint16_t) || !stream.read<uint16_t>(serverId)) {
                        throw std::runtime_error("Invalid ITEM_ATTR_SERVERID.");
                    }
                    serverId = remapServerId(serverId);
                    break;
                }

                case ITEM_ATTR_SPEED: {
                    if (dataLength != sizeof(uint16_t) || !stream.read<uint16_t>(speed)) {
                        throw std::runtime_error("Invalid ITEM_ATTR_SPEED.");
                    }
                    break;
                }

                case ITEM_ATTR_MINIMAPCOLOR: {
                    if (dataLength != sizeof(uint16_t) || !stream.read<uint16_t>(minimapColor)) {
                        throw std::runtime_error("Invalid ITEM_ATTR_MINIMAPCOLOR.");
                    }
                    break;
                }

                case ITEM_ATTR_TOPORDER: {
                    if (dataLength != sizeof(uint8_t) || !stream.read<uint8_t>(topOrder)) {
                        throw std::runtime_error("Invalid ITEM_ATTR_TOPORDER.");
                    }
                    break;
                }

                default: {
                    if (!stream.skip(dataLength)) {
                        throw std::runtime_error("Invalid items.otb attribute payload.");
                    }
                    break;
                }
            }
        }

        if (serverId == 0) {
            continue;
        }

        ItemInfo info;
        info.isGround = itemNode.type == ITEM_GROUP_GROUND;
        info.alwaysOnTop = (flags & FLAG_ALWAYSONTOP) != 0;
        info.blockSolid = (flags & FLAG_BLOCK_SOLID) != 0;
        info.blockPathFind = (flags & FLAG_BLOCK_PATHFIND) != 0;
        info.alwaysOnTopOrder = topOrder;
        info.minimapColor = static_cast<uint8_t>(std::min<uint16_t>(minimapColor, 255));
        info.groundSpeed = speed;

        itemInfoByServerId[serverId] = info;
    }

    return itemInfoByServerId;
}

AreaContext nearestAreaContext(const std::vector<NodeState>& stack)
{
    for (auto it = stack.rbegin(); it != stack.rend(); ++it) {
        if (it->area.has_value()) {
            return *it->area;
        }
    }
    throw std::runtime_error("Tile area context not found while parsing map.");
}

void finalizeNodeProps(std::vector<NodeState>& stack, size_t index)
{
    NodeState& node = stack[index];
    if (node.propsFinalized) {
        return;
    }

    node.propsFinalized = true;

    if (node.type == OTBM_TILE_AREA) {
        Cursor cursor(node.props);
        AreaContext area;
        area.x = cursor.readU16();
        area.y = cursor.readU16();
        area.z = cursor.readU8();
        node.area = area;
        return;
    }

    if (node.type == OTBM_TILE || node.type == OTBM_HOUSETILE) {
        AreaContext area = nearestAreaContext(stack);
        Cursor cursor(node.props);

        TileContext tile;
        tile.x = static_cast<uint16_t>(area.x + cursor.readU8());
        tile.y = static_cast<uint16_t>(area.y + cursor.readU8());
        tile.z = area.z;

        if (node.type == OTBM_HOUSETILE) {
            cursor.readU32();
        }

        while (!cursor.empty()) {
            const uint8_t attribute = cursor.readU8();
            switch (attribute) {
                case OTBM_ATTR_TILE_FLAGS:
                    cursor.readU32();
                    break;

                case OTBM_ATTR_ITEM:
                    tile.topLevelItems.push_back(remapServerId(cursor.readU16()));
                    break;

                default:
                    throw std::runtime_error("Unknown tile attribute in OTBM stream.");
            }
        }

        node.tile = std::move(tile);
        return;
    }

    if (node.type == OTBM_ITEM) {
        Cursor cursor(node.props);
        node.itemServerId = remapServerId(cursor.readU16());
    }
}

void parseMapToBlocks(
    const std::string& mapPath,
    const std::unordered_map<uint16_t, ItemInfo>& itemInfoByServerId,
    BlockMap blocksByFloor[static_cast<size_t>(MAX_Z) + 1],
    uint64_t& tileCount,
    uint64_t& blockCount)
{
    std::ifstream input(mapPath, std::ios::binary);
    if (!input) {
        throw std::runtime_error("Unable to open map file: " + mapPath);
    }

    const std::vector<uint8_t> data((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
    if (data.size() < 6) {
        throw std::runtime_error("Map file is too small.");
    }

    if (data[4] != NODE_START) {
        throw std::runtime_error("Unexpected OTBM root marker.");
    }

    std::vector<NodeState> stack;
    stack.reserve(16);
    stack.push_back(NodeState{data[5], false, true});

    for (size_t i = 6; i < data.size();) {
        const uint8_t byte = data[i];

        if (byte == NODE_ESCAPE) {
            if (stack.empty() || i + 1 >= data.size()) {
                throw std::runtime_error("Invalid escape sequence in OTBM.");
            }

            if (stack.back().collectingProps) {
                stack.back().props.push_back(data[i + 1]);
            }
            i += 2;
            continue;
        }

        if (byte == NODE_START) {
            if (i + 1 >= data.size()) {
                throw std::runtime_error("Unexpected end of OTBM while reading node type.");
            }

            if (!stack.empty() && stack.back().collectingProps) {
                finalizeNodeProps(stack, stack.size() - 1);
                stack.back().collectingProps = false;
            }

            const uint8_t type = data[i + 1];
            const bool collectProps = (type == OTBM_TILE_AREA || type == OTBM_TILE || type == OTBM_HOUSETILE || type == OTBM_ITEM);
            stack.push_back(NodeState{type, collectProps, !collectProps});
            i += 2;
            continue;
        }

        if (byte == NODE_END) {
            if (stack.empty()) {
                throw std::runtime_error("Unexpected node end in OTBM.");
            }

            if (stack.back().collectingProps) {
                finalizeNodeProps(stack, stack.size() - 1);
                stack.back().collectingProps = false;
            }

            NodeState finished = std::move(stack.back());
            stack.pop_back();

            if (finished.type == OTBM_ITEM && !stack.empty()) {
                NodeState& parent = stack.back();
                if ((parent.type == OTBM_TILE || parent.type == OTBM_HOUSETILE) && parent.tile.has_value() && finished.itemServerId != 0) {
                    parent.tile->topLevelItems.push_back(finished.itemServerId);
                }
            } else if ((finished.type == OTBM_TILE || finished.type == OTBM_HOUSETILE) && finished.tile.has_value()) {
                setTile(blocksByFloor, *finished.tile, buildTile(*finished.tile, itemInfoByServerId));
                ++tileCount;
            }

            ++i;
            if (stack.empty()) {
                break;
            }
            continue;
        }

        if (!stack.empty() && stack.back().collectingProps) {
            stack.back().props.push_back(byte);
        }
        ++i;
    }

    for (uint8_t z = 0; z <= MAX_Z; ++z) {
        blockCount += blocksByFloor[z].size();
    }
}

template <typename T>
void writeLE(std::ofstream& out, T value)
{
    out.write(reinterpret_cast<const char*>(&value), sizeof(T));
}

void writeString(std::ofstream& out, const std::string& value)
{
    const auto length = static_cast<uint16_t>(value.size());
    writeLE<uint16_t>(out, length);
    out.write(value.data(), value.size());
}

void writeOtmm(const std::string& outputPath, const BlockMap blocksByFloor[static_cast<size_t>(MAX_Z) + 1])
{
    std::filesystem::path output(outputPath);
    std::filesystem::create_directories(output.parent_path());

    std::ofstream out(output, std::ios::binary | std::ios::trunc);
    if (!out) {
        throw std::runtime_error("Unable to create output file: " + outputPath);
    }

    writeLE<uint32_t>(out, OTMM_SIGNATURE);
    writeLE<uint16_t>(out, 0);
    writeLE<uint16_t>(out, OTMM_VERSION);
    writeLE<uint32_t>(out, 0);
    writeString(out, "OTMM 1.0");

    const uint16_t dataStart = static_cast<uint16_t>(out.tellp());
    out.seekp(4, std::ios::beg);
    writeLE<uint16_t>(out, dataStart);
    out.seekp(dataStart, std::ios::beg);

    std::vector<uint8_t> compressed(compressBound(BLOCK_SIZE * BLOCK_SIZE * sizeof(MinimapTile)));

    for (uint8_t z = 0; z <= MAX_Z; ++z) {
        for (const auto& [index, block] : blocksByFloor[z]) {
            if (!block.hasSeenTile) {
                continue;
            }

            const uint16_t blockX = static_cast<uint16_t>((index % BLOCKS_PER_AXIS) * BLOCK_SIZE);
            const uint16_t blockY = static_cast<uint16_t>((index / BLOCKS_PER_AXIS) * BLOCK_SIZE);

            writeLE<uint16_t>(out, blockX);
            writeLE<uint16_t>(out, blockY);
            writeLE<uint8_t>(out, z);

            uLongf compressedSize = compressed.size();
            const int compressionResult = compress2(
                compressed.data(),
                &compressedSize,
                reinterpret_cast<const Bytef*>(block.tiles.data()),
                BLOCK_SIZE * BLOCK_SIZE * sizeof(MinimapTile),
                3
            );

            if (compressionResult != Z_OK) {
                throw std::runtime_error("Failed to compress OTMM block.");
            }

            writeLE<uint16_t>(out, static_cast<uint16_t>(compressedSize));
            out.write(reinterpret_cast<const char*>(compressed.data()), compressedSize);
        }
    }

    writeLE<uint16_t>(out, 0);
    writeLE<uint16_t>(out, 0);
    writeLE<uint8_t>(out, 0);
}

} // namespace

int main(int argc, char** argv)
{
    try {
        if (argc != 4) {
            std::cerr << "usage: " << argv[0] << " <items.otb> <map.otbm> <output.otmm>\n";
            return 1;
        }

        const std::string itemsPath = argv[1];
        const std::string mapPath = argv[2];
        const std::string outputPath = argv[3];

        BlockMap blocksByFloor[static_cast<size_t>(MAX_Z) + 1];

        const auto itemInfoByServerId = loadItemInfo(itemsPath);

        uint64_t tileCount = 0;
        uint64_t blockCount = 0;
        parseMapToBlocks(mapPath, itemInfoByServerId, blocksByFloor, tileCount, blockCount);

        writeOtmm(outputPath, blocksByFloor);

        const auto outputSize = std::filesystem::file_size(outputPath);
        std::cout
            << "Generated " << outputPath
            << " with " << tileCount << " tiles across " << blockCount << " OTMM blocks ("
            << outputSize << " bytes)." << std::endl;
        return 0;
    } catch (const std::exception& exception) {
        std::cerr << "generate_otmm_minimap failed: " << exception.what() << std::endl;
        return 1;
    }
}
