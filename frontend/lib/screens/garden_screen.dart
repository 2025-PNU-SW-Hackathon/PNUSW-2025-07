import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GardenItem {
  final int id;
  final int user_id;
  final String item_type;
  final String item_name;
  final String item_image;
  final int position_x;
  final int position_y;
  final int layer;
  final bool is_equipped;
  final DateTime created_at;

  GardenItem({
    required this.id,
    required this.user_id,
    required this.item_type,
    required this.item_name,
    required this.item_image,
    required this.position_x,
    required this.position_y,
    required this.layer,
    required this.is_equipped,
    required this.created_at,
  });

  factory GardenItem.fromJson(Map<String, dynamic> json) {
    return GardenItem(
      id: json['id'] ?? 0,
      user_id: json['user_id'] ?? 0,
      item_type: json['item_type'] ?? '',
      item_name: json['item_name'] ?? '',
      item_image: json['item_image'] ?? '',
      position_x: json['position_x'] ?? 0,
      position_y: json['position_y'] ?? 0,
      layer: json['layer'] ?? 0,
      is_equipped: json['is_equipped'] ?? false,
      created_at: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class GardenScreen extends StatefulWidget {
  final String accessToken;
  const GardenScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  GardenScreenState createState() => GardenScreenState();
}

class GardenScreenState extends State<GardenScreen> {
  bool isLoading = true;
  bool _disposed = false;
  
  // 정원 정보
  Map<String, dynamic> gardenInfo = {};
  List<Map<String, dynamic>> inventory = [];
  List<Map<String, dynamic>> shopItems = [];
  List<GardenItem> _gardenItems = [];
  List<GardenItem> _inventoryItems = [];
  
  // 씨앗 및 출석 정보
  int _seeds = 0;
  int _attendanceStreak = 0;
  DateTime? _lastAttendanceDate;
  
  // 그리드 크기 (6x12)
  static const int gridWidth = 6;
  static const int gridHeight = 12;
  List<List<String?>> gardenGrid = List.generate(
    gridHeight, 
    (i) => List.generate(gridWidth, (j) => null)
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_disposed) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      // 정원 정보, 인벤토리, 상점 아이템을 병렬로 로드
      final results = await Future.wait([
        ApiService.getGardenInfo(widget.accessToken),
        ApiService.getInventory(widget.accessToken),
        ApiService.getShopItems(),
      ]);

      if (_disposed) return;

      

      setState(() {
        // 정원 정보 설정 (씨앗, 출석 정보만 사용)
        gardenInfo = (results[0] as Map<String, dynamic>?) ?? <String, dynamic>{};
        _seeds = gardenInfo['seeds'] ?? 0;
        _attendanceStreak = gardenInfo['attendance_streak'] ?? 0;
        _lastAttendanceDate = gardenInfo['last_attendance_date'] != null 
            ? DateTime.parse(gardenInfo['last_attendance_date']) 
            : null;
        
        // 인벤토리에서 배치된 아이템만 정원에 표시
        final inventoryResponse = results[1] as Map<String, dynamic>?;
        final inventoryList = inventoryResponse?['items'] as List<dynamic>?;
        inventory = inventoryList?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
        
        // 배치된 아이템들만 정원에 표시
        _gardenItems = (inventoryList?.where((item) => item['is_equipped'] == true).map((item) {
          return GardenItem(
            id: item['id'] ?? 0,
            user_id: 0,
            item_type: item['item_type'] ?? '',
            item_name: item['item_name'] ?? '',
            item_image: item['item_image'] ?? '',
            position_x: item['position_x'] ?? 0,
            position_y: item['position_y'] ?? 0,
            layer: item['layer'] ?? 0,
            is_equipped: item['is_equipped'] ?? false,
            created_at: DateTime.now(),
          );
        }).toList() ?? []) as List<GardenItem>;
        
        // 배치되지 않은 아이템들만 인벤토리에 표시
        _inventoryItems = (inventoryList?.where((item) => item['is_equipped'] == false).map((item) {
          return GardenItem(
            id: item['id'] ?? 0,
            user_id: 0,
            item_type: item['item_type'] ?? '',
            item_name: item['item_name'] ?? '',
            item_image: item['item_image'] ?? '',
            position_x: item['position_x'] ?? 0,
            position_y: item['position_y'] ?? 0,
            layer: item['layer'] ?? 0,
            is_equipped: item['is_equipped'] ?? false,
            created_at: DateTime.now(),
          );
        }).toList() ?? []) as List<GardenItem>;
        
        final shopResponse = results[2] as Map<String, dynamic>?;
        final shopList = shopResponse?['items'] as List<dynamic>?;
        shopItems = shopList?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
        
        isLoading = false;
        

      });
      
      // 정원 그리드 초기화
      _initializeGardenGrid();
      
      // 데이터 로딩 후 최종 확인
      
      
    } catch (e) {
      if (_disposed) return;
      
      setState(() {
        isLoading = false;
      });
      
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: ${e.toString()}')),
        );
      }
    }
  }

  void _initializeGardenGrid() {
    // 배치된 아이템들을 그리드에 로드 (이미 is_equipped가 true인 아이템들만 _gardenItems에 있음)
    for (var item in _gardenItems) {
      if (item.position_x >= 0 && item.position_x < gridWidth && item.position_y >= 0 && item.position_y < gridHeight) {
        gardenGrid[item.position_y][item.position_x] = item.item_name;
      }
    }
  }

  // 외부에서 호출할 수 있는 캐시 갱신 메서드
  void refreshCache() {
    _loadData();
  }

  Future<void> _checkAttendance() async {
    try {
      final result = await ApiService.checkAttendance(widget.accessToken);
      
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '출석 체크 완료'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // 정원 정보 새로고침
        _loadData();
      }
    } catch (e) {
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('출석 체크 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _purchaseItem(int templateId, {int quantity = 1}) async {
    try {
      final result = await ApiService.purchaseItem(
        accessToken: widget.accessToken,
        templateId: templateId,
        quantity: quantity,
      );
      
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '구매 완료'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // 인벤토리 새로고침
        _loadData();
      }
    } catch (e) {
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구매 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _placeItem(int itemId, int gridX, int gridY, [String? variant]) async {
    try {
      final result = await ApiService.equipItem(
        accessToken: widget.accessToken,
        itemId: itemId,
        positionX: gridX,
        positionY: gridY,
        variant: variant,
      );
      
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '배치 완료'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // 데이터 새로고침으로 그리드 업데이트
        _loadData();
      }
    } catch (e) {
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('배치 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _removeItem(int itemId) async {
    try {
      final result = await ApiService.unequipItem(
        accessToken: widget.accessToken,
        itemId: itemId,
      );
      
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '제거 완료'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        _loadData();
      }
    } catch (e) {
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('제거 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _sellItem(int itemId, int quantity) async {
    try {
      final result = await ApiService.sellItem(
        accessToken: widget.accessToken,
        itemId: itemId,
        quantity: quantity,
      );
      
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '판매 완료'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        _loadData();
      }
    } catch (e) {
      if (mounted && !_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('판매 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showSellDialog(GardenItem item, int maxQuantity) {
    int quantity = 1;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${item.item_name} 판매하기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _getItemWidget(item, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.item_name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '보유 수량: $maxQuantity개',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('판매 수량: '),
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$quantity'),
                        IconButton(
                          onPressed: quantity < maxQuantity ? () => setState(() => quantity++) : null,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '판매 가격: ${quantity * 5} 씨앗', // 기본 판매가 5씨앗
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sellItem(item.id, quantity);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('판매'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlacementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('아이템 배치'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final item = inventory[index];
              final isEquipped = item['is_equipped'] ?? false;
              
              return GestureDetector(
                onTap: isEquipped ? null : () {
                  Navigator.pop(context);
                  _showGridSelectionDialog(item);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isEquipped ? Colors.grey.withOpacity(0.3) : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isEquipped ? Colors.grey : Colors.green,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getItemWidget(
                        GardenItem.fromJson(item),
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['item_name'],
                        style: TextStyle(
                          fontSize: 8,
                          color: isEquipped ? Colors.grey : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isEquipped)
                        const Text(
                          '배치됨',
                          style: TextStyle(fontSize: 6, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(Map<String, dynamic> item) {
    int quantity = 1;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${item['item_name']} 구매하기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getRarityColor(item['rarity']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _getItemWidget(
                      GardenItem.fromJson(item),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['item_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.eco, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('${item['price']}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('수량: '),
                  Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$quantity'),
                        IconButton(
                          onPressed: () => setState(() => quantity++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '총 가격: ${item['price'] * quantity} 씨앗',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _purchaseItem(item['id'], quantity: quantity);
              },
              child: const Text('구매'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGridSelectionDialog(Map<String, dynamic> item) {
    // 아이템 타입에 따른 변형 옵션들 (특수문자 없는 파일들만)
    List<String> variants = [];
    String itemType = item['item_type'] ?? '';
    String itemName = item['item_name'] ?? '';
    
    if (itemName.contains('연꽃')) {
      variants = ['light_green', 'green', 'moss_green', 'dark_moss_green'];
    } else if (itemName.contains('꽃')) {
      variants = ['small_paddles', 'big_paddles'];
    } else if (itemName.contains('돌담') || itemName.contains('벽돌')) {
      variants = ['horizontal', 'vertical'];
    }
    
    String? selectedVariant = variants.isNotEmpty ? variants.first : null;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${item['item_name']} 배치하기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (variants.isNotEmpty) ...[
                const Text('변형 선택:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selectedVariant,
                  items: variants.map((variant) => DropdownMenuItem(
                    value: variant,
                    child: Text(_getVariantDisplayName(variant)),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedVariant = value),
                ),
                const SizedBox(height: 16),
              ],
              const Text('위치 선택:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.maxFinite,
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: gridWidth * gridHeight,
                  itemBuilder: (context, index) {
                    final x = index % gridWidth;
                    final y = index ~/ gridWidth;
                    final isOccupied = gardenGrid[y][x] != null;
                    
                    return GestureDetector(
                      onTap: isOccupied ? null : () {
                        Navigator.pop(context);
                        _placeItem(item['id'], x, y, selectedVariant);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isOccupied ? Colors.red.withOpacity(0.3) : Colors.brown.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: isOccupied ? Colors.red : Colors.brown,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: isOccupied
                              ? const Icon(Icons.close, color: Colors.red, size: 12)
                              : const Icon(Icons.add, color: Colors.brown, size: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInventoryDialog(GardenItem item, int x, int y) {
    if (!mounted || _disposed) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('아이템 배치'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _inventoryItems.length,
            itemBuilder: (context, index) {
              final inventoryItem = _inventoryItems[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  child: _getItemWidget(inventoryItem, size: 32),
                ),
                title: Text(
                  inventoryItem.item_name,
                  style: TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${inventoryItem.item_type}',
                  style: TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  if (mounted && !_disposed) {
                    _showDirectionSelectionDialog(inventoryItem, x, y);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소'),
          ),
        ],
      ),
    );
  }

  void _showDirectionSelectionDialog(GardenItem item, int x, int y) {
    if (!mounted || _disposed) return;
    
    List<String> variants = _getVariantsForItem(item);
    
    if (variants.isEmpty) {
      // 방향 선택이 필요 없는 아이템은 바로 배치
      _placeItem(item.id, x, y);
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.item_name} ${_getVariantTypeName(item)} 선택'),
        content: Container(
          width: double.maxFinite,
          height: 300, // 높이 증가
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: variants.length,
            itemBuilder: (context, index) {
              String variant = variants[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  if (mounted && !_disposed) {
                    _placeItem(item.id, x, y, variant);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 썸네일 이미지 추가
                      Container(
                        width: 40,
                        height: 40,
                        child: _getVariantThumbnail(item, variant),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getVariantDisplayName(variant),
                        style: TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소'),
          ),
        ],
      ),
    );
  }

  List<String> _getVariantsForItem(GardenItem item) {
    String itemName = item.item_name;
    
    // 울타리
    if (itemName.contains('울타리')) {
      return ['horizontal', 'vertical', 'left', 'right', 'top', 'bottom', 'top_left', 'top_right', 'bottom_left', 'bottom_right'];
    }
    
    // 부시
    if (itemName.contains('부시')) {
      return ['horizontal', 'vertical', 'left', 'right', 'top', 'bottom', 'top_left', 'top_right', 'bottom_left', 'bottom_right'];
    }
    
    // 다리
    if (itemName.contains('다리')) {
      return ['horizontal', 'vertical', 'left', 'right', 'top', 'bottom', 'left_short', 'right_short', 'top_short', 'bottom_short'];
    }
    
    // 연못
    if (itemName.contains('연못') && !itemName.contains('테두리')) {
      return ['center', 'top_left', 'top_right', 'bottom_left', 'bottom_right', 'left', 'right', 'top', 'bottom'];
    }
    
    // 연못 테두리
    if (itemName.contains('연못 테두리')) {
      return ['left', 'right', 'top', 'bottom', 'top_left', 'top_right', 'bottom_left', 'bottom_right'];
    }
    
    // 꽃
    if (itemName.contains('꽃') && !itemName.contains('봉오리')) {
      return ['small_paddles', 'big_paddles'];
    }
    
    // 꽃봉오리 (Bloom)
    if (itemName.contains('꽃봉오리')) {
      return ['bud', 'big_bud', 'flower'];
    }
    
    // 연꽃
    if (itemName.contains('연꽃')) {
      return ['light_green', 'green', 'moss_green', 'dark_moss_green'];
    }
    
    // 채소
    if (['토마토', '딸기', '당근', '양파', '마늘', '오이', '체리 토마토', '무'].any((veggie) => itemName.contains(veggie))) {
      return ['paddle'];
    }
    
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isPhone = screenWidth < 400;
    
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('마음 정원'),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: isPhone, // 작은 화면에서는 스크롤 가능
            labelStyle: TextStyle(
              fontSize: isTablet ? 16.0 : (isPhone ? 12.0 : 14.0),
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: isTablet ? 16.0 : (isPhone ? 12.0 : 14.0),
            ),
            tabs: [
              Tab(text: '정원'),
              Tab(text: '내 씨앗'),
              Tab(text: '상점'),
              Tab(text: '인벤토리'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildGardenTab(),
                  _buildSeedsTab(),
                  _buildShopTab(),
                  _buildInventoryTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildGardenTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 정원 그리드 (큰 크기)
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '내 정원',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: _showPlacementDialog,
                          icon: const Icon(Icons.add_circle, color: Colors.green, size: 28),
                          tooltip: '아이템 배치',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513), // 갈색 땅
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.brown, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _buildGardenGrid(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // 하단 여백 추가
          ],
        ),
      ),
    );
  }

  Widget _buildSeedsTab() {
    // 클래스 변수 사용
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 씨앗 정보 카드
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.eco, color: Colors.green, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          '$_seeds',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '내 씨앗',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 출석 체크 카드
            Card(
              child: InkWell(
                onTap: _checkAttendance,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue, size: 32),
                      const SizedBox(height: 12),
                      const Text(
                        '출석 체크',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '연속 출석: ${_attendanceStreak}일',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '씨앗 받기',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getItemCategory(String itemName) {
    if (itemName.contains('꽃') && !itemName.contains('봉오리')) return '꽃';
    if (itemName.contains('꽃봉오리')) return '꽃봉오리';
    if (itemName.contains('부시')) return '부시';
    if (itemName.contains('울타리')) return '울타리';
    if (itemName.contains('다리')) return '다리';
    if (itemName.contains('연못') && !itemName.contains('테두리')) return '연못';
    if (itemName.contains('연못 테두리')) return '연못 테두리';
    if (itemName.contains('연꽃')) return '연꽃';
    if (itemName.contains('물고기')) return '물고기';
    if (['토마토', '딸기', '당근', '양파', '마늘', '오이', '체리 토마토', '무'].any((veggie) => itemName.contains(veggie))) return '채소';
    if (itemName.contains('돌담') || itemName.contains('벽돌')) return '장식';
    if (itemName.contains('배경')) return '배경';
    // 기타 카테고리 제거 - 모든 아이템이 명확한 카테고리를 가지도록 함
    return '장식';
  }

  Widget _buildShopTab() {
    // 카테고리별로 아이템 그룹화
    Map<String, List<Map<String, dynamic>>> categorizedItems = {};
    
    for (var item in shopItems) {
      String category = _getItemCategory(item['item_name']);
      if (!categorizedItems.containsKey(category)) {
        categorizedItems[category] = [];
      }
      categorizedItems[category]!.add(item);
    }
    
    List<String> categories = categorizedItems.keys.toList()..sort();
    
    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          // 카테고리 탭바
          Container(
            color: Colors.grey[100],
            child: TabBar(
              isScrollable: true,
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.green,
              tabs: categories.map((category) => Tab(text: category)).toList(),
            ),
          ),
          // 탭 내용
          Expanded(
            child: TabBarView(
              children: categories.map((category) {
                List<Map<String, dynamic>> categoryItems = categorizedItems[category]!;
                
                return RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: categoryItems.length,
                    itemBuilder: (context, index) {
                      final item = categoryItems[index];
                      final price = item['price'] ?? 0;
                      final rarity = item['rarity'] ?? 'common';
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: _getRarityColor(rarity).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: _getItemWidget(
                                      GardenItem.fromJson(item),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['item_name'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item['item_description'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.eco, size: 14, color: Colors.green),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$price',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                            // 상점 카드에서는 희귀도 배지 숨김 처리
                                            // 상점 카드에서는 레이어 표시는 숨김 처리
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _showPurchaseDialog(item),
                                      icon: const Icon(Icons.shopping_cart, size: 14),
                                      label: const Text('구매하기', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    // 배치되지 않은 아이템들만 필터링하고 그룹화
    Map<String, List<GardenItem>> groupedItems = {};
    
    for (var item in _inventoryItems) {
      String key = '${item.item_name}';
      if (!groupedItems.containsKey(key)) {
        groupedItems[key] = [];
      }
      groupedItems[key]!.add(item);
    }
    
    List<MapEntry<String, List<GardenItem>>> sortedItems = groupedItems.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sortedItems.length,
        itemBuilder: (context, index) {
          final entry = sortedItems[index];
          final itemName = entry.key;
          final items = entry.value;
          final count = items.length;
          final firstItem = items.first;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _getItemWidget(firstItem, size: 24),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(itemName)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '개수: $count개',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '인벤토리에 보관중',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getLayerColor(firstItem.layer),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getLayerName(firstItem.layer),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.sell, color: Colors.orange),
                onPressed: () => _showSellDialog(firstItem, count),
                tooltip: '판매하기',
              ),
            ),
          );
        },
      ),
    );
  }

  void _removeItemFromGrid(Map<String, dynamic> item) {
    // 그리드에서 해당 아이템 찾기
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        if (gardenGrid[y][x] == item['item_name']) {
          _removeItem(item['id']);
          return;
        }
      }
    }
  }

  String _getItemTypeByName(String itemName) {
    // 아이템 이름으로 타입 추정
    if (itemName.contains('꽃') || itemName.contains('flower')) return 'flower';
    if (itemName.contains('화분') || itemName.contains('pot')) return 'pot';
    if (itemName.contains('장식') || itemName.contains('decoration') || itemName.contains('울타리')) return 'decoration';
    return 'flower';
  }

  String? _getItemImageByName(String itemName) {
    if (itemName.contains('흰색 울타리')) {
      return 'assets/images/garden/fence/white/Direction=↔️ Horizontal, Color=White.png';
    }
    if (itemName.contains('연한 나무 울타리')) {
      return 'assets/images/garden/fence/light_wood/Direction=↔️ Horizontal, Color=Light Wood.png';
    }
    if (itemName.contains('노란 꽃')) {
      return 'assets/images/garden/flowers/yellow.png';
    }
    if (itemName.contains('보라 꽃')) {
      return 'assets/images/garden/flowers/purple.png';
    }
    if (itemName.contains('분홍 꽃')) {
      return 'assets/images/garden/flowers/pink.png';
    }
    if (itemName.contains('흰 꽃')) {
      return 'assets/images/garden/flowers/big_paddle/white_small_paddles.png';
    }
    if (itemName.contains('복숭아 꽃')) {
      return 'assets/images/garden/flowers/big_paddle/peach_small_paddles.png';
    }
    if (itemName.contains('파란 꽃')) {
      return 'assets/images/garden/flowers/big_paddle/blue_small_paddles.png';
    }
    if (itemName.contains('돌담')) {
      return 'assets/images/garden/rocks/rocks.png';
    }
    if (itemName.contains('벽돌') && !itemName.contains('원형')) {
      return 'assets/images/garden/rocks/bricks.png';
    }
    if (itemName.contains('원형 벽돌')) {
      return 'assets/images/garden/rocks/circle_bricks.png';
    }
    if (itemName.contains('연한 초록 부시')) {
      return 'assets/images/garden/bushes/bush/light_green/horizontal_regular.png';
    }
    if (itemName.contains('초록 부시')) {
      return 'assets/images/garden/bushes/bush/green/horizontal_regular.png';
    }
    if (itemName.contains('이끼 초록 부시')) {
      return 'assets/images/garden/bushes/bush/moss_green/horizontal_regular.png';
    }
    if (itemName.contains('어두운 이끼 초록 부시')) {
      return 'assets/images/garden/bushes/bush/dark_moss_green/horizontal_regular.png';
    }
    if (itemName.contains('나무 다리')) {
      return 'assets/images/garden/bridge/bridge_horizontal.png';
    }
    if (itemName.contains('연못') && !itemName.contains('테두리')) {
      return 'assets/images/garden/pond/pond/Direction=🔄 Center.png';
    }
    if (itemName.contains('빨간 물고기')) {
      return 'assets/images/garden/fishes/red.png';
    }
    if (itemName.contains('주황 물고기')) {
      return 'assets/images/garden/fishes/orange.png';
    }
    if (itemName.contains('연꽃')) {
      return 'assets/images/garden/lotus/light_green.png';
    }
    if (itemName.contains('토마토')) {
      return 'assets/images/garden/veggie/single/Type=Tomato.png';
    }
    if (itemName.contains('딸기')) {
      return 'assets/images/garden/veggie/single/Type=Strawberry.png';
    }
    if (itemName.contains('당근')) {
      return 'assets/images/garden/veggie/single/Type=Carrot.png';
    }
    if (itemName.contains('양파')) {
      return 'assets/images/garden/veggie/single/Type=Onion.png';
    }
    if (itemName.contains('마늘')) {
      return 'assets/images/garden/veggie/single/Type=Garlic.png';
    }
    if (itemName.contains('오이')) {
      return 'assets/images/garden/veggie/single/Type=Cucumber.png';
    }
    if (itemName.contains('체리 토마토')) {
      return 'assets/images/garden/veggie/single/Type=Cherry Tomatoes.png';
    }
    if (itemName.contains('무')) {
      return 'assets/images/garden/veggie/single/Type=Radish.png';
    }
    if (itemName.contains('잔디 배경')) {
      return 'assets/images/garden/backgrounds/Options=🌱 Grass.png';
    }
    if (itemName.contains('모래 배경')) {
      return 'assets/images/garden/backgrounds/Options=🏝️ Sand.png';
    }
    if (itemName.contains('흙 배경')) {
      return 'assets/images/garden/backgrounds/Options=🪱 Soil.png';
    }
    
    // 새로운 아이템 타입들
    if (itemName.contains('꽃봉오리')) {
      String color = 'Yellow';
      if (itemName.contains('노란')) color = 'Yellow';
      else if (itemName.contains('보라')) color = 'Purple';
      else if (itemName.contains('분홍')) color = 'Pink';
      else if (itemName.contains('복숭아')) color = 'Peach';
      return 'assets/images/garden/bloom/color/Size=Bud, Color=$color.png';
    }
    if (itemName.contains('연한 초록 연꽃')) {
      return 'assets/images/garden/lotus/light_green.png';
    }
    if (itemName.contains('초록 연꽃')) {
      return 'assets/images/garden/lotus/green.png';
    }
    if (itemName.contains('이끼 초록 연꽃')) {
      return 'assets/images/garden/lotus/moss_green.png';
    }
    if (itemName.contains('어두운 이끼 초록 연꽃')) {
      return 'assets/images/garden/lotus/dark_moss_green.png';
    }
    if (itemName.contains('초록 연못 테두리')) {
      return 'assets/images/garden/pond/pond_borders/green/Border Option=🌳 Bush, Color=Green, Direction=⬅️ Left.png';
    }
    if (itemName.contains('연한 초록 연못 테두리')) {
      return 'assets/images/garden/pond/pond_borders/light_green/Border Option=🌳 Bush, Color=Light Green, Direction=⬅️ Left.png';
    }
    if (itemName.contains('회색 연못 테두리')) {
      return 'assets/images/garden/pond/pond_borders/grey/Border Option=🌳 Bush, Color=Grey, Direction=⬅️ Left.png';
    }
    if (itemName.contains('어두운 회색 연못 테두리')) {
      return 'assets/images/garden/pond/pond_borders/dark_grey/Border Option=🌳 Bush, Color=Dark Grey, Direction=⬅️ Left.png';
    }
    return null;
  }

  Widget _getItemWidget(GardenItem item, {double size = 16}) {
    // 먼저 데이터베이스에 저장된 이미지 경로를 사용
    String? imagePath = item.item_image;
    
    // 데이터베이스에 저장된 이미지가 없으면 기본 이미지 사용
    if (imagePath == null || imagePath.isEmpty) {
      imagePath = _getItemImageByName(item.item_name);
    }
    
    if (imagePath != null && imagePath.isNotEmpty) {
      // 실제 이미지가 있으면 이미지 사용
      if (size == double.infinity) {
        return Image.asset(
          imagePath,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // 이미지 로드 실패시 아이콘 사용
            return Center(
              child: Icon(_getItemIcon(item.item_type), size: 32),
            );
          },
        );
      } else {
        return Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // 이미지 로드 실패시 아이콘 사용
            return Icon(_getItemIcon(item.item_type), size: size);
          },
        );
      }
    } else {
      // 이미지가 없으면 아이콘 사용
      if (size == double.infinity) {
        return Center(
          child: Icon(_getItemIcon(item.item_type), size: 32),
        );
      } else {
        return Icon(_getItemIcon(item.item_type), size: size);
      }
    }
  }

  IconData _getItemIcon(String itemType) {
    switch (itemType) {
      case 'flower':
        return Icons.local_florist;
      case 'pot':
        return Icons.eco;
      case 'decoration':
        return Icons.star;
      default:
        return Icons.eco;
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common':
        return Colors.grey;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRarityText(String rarity) {
    switch (rarity) {
      case 'common':
        return '일반';
      case 'rare':
        return '희귀';
      case 'epic':
        return '영웅';
      case 'legendary':
        return '전설';
      default:
        return '일반';
    }
  }

  String _getVariantDisplayName(String variant) {
    switch (variant) {
      case 'horizontal':
        return '가로';
      case 'vertical':
        return '세로';
      case 'left':
        return '왼쪽';
      case 'right':
        return '오른쪽';
      case 'top':
        return '위쪽';
      case 'bottom':
        return '아래쪽';
      case 'top_left':
        return '왼쪽 위';
      case 'top_right':
        return '오른쪽 위';
      case 'bottom_left':
        return '왼쪽 아래';
      case 'bottom_right':
        return '오른쪽 아래';
      case 'center':
        return '중앙';
      case 'small_paddles':
        return '작은 꽃';
      case 'big_paddles':
        return '큰 꽃';
      case 'bud':
        return '꽃봉오리';
      case 'big_bud':
        return '큰 꽃봉오리';
      case 'flower':
        return '꽃';
      case 'light_green':
        return '연한 초록';
      case 'green':
        return '초록';
      case 'moss_green':
        return '이끼 초록';
      case 'dark_moss_green':
        return '어두운 이끼';
      case 'single':
        return '단일';
      case 'paddle':
        return '패들';
      case 'left_short':
        return '왼쪽 짧은';
      case 'right_short':
        return '오른쪽 짧은';
      case 'top_short':
        return '위쪽 짧은';
      case 'bottom_short':
        return '아래쪽 짧은';
      default:
        return variant;
    }
  }

  String _getVariantTypeName(GardenItem item) {
    if (item.item_name.contains('꽃') && !item.item_name.contains('봉오리')) {
      return '크기';
    }
    if (item.item_name.contains('꽃봉오리')) {
      return '크기';
    }
    if (item.item_name.contains('부시')) {
      return '방향';
    }
    if (item.item_name.contains('울타리')) {
      return '방향';
    }
    if (item.item_name.contains('다리')) {
      return '방향';
    }
    if (item.item_name.contains('연못') && !item.item_name.contains('테두리')) {
      return '위치';
    }
    if (item.item_name.contains('연못 테두리')) {
      return '방향';
    }
    if (item.item_name.contains('연꽃')) {
      return '색상';
    }
    if (['토마토', '딸기', '당근', '양파', '마늘', '오이', '체리 토마토', '무'].any((veggie) => item.item_name.contains(veggie))) {
      return '배치';
    }
    return '옵션';
  }

  Widget _getVariantThumbnail(GardenItem item, String variant) {
    String? imagePath = null;
    

    
    // 꽃의 경우 크기별 이미지
    if (item.item_name.contains('꽃')) {
      String color = 'yellow'; // 기본값
      if (item.item_name.contains('노란')) color = 'yellow';
      else if (item.item_name.contains('파란')) color = 'blue';
      else if (item.item_name.contains('보라')) color = 'purple';
      else if (item.item_name.contains('분홍')) color = 'pink';
      else if (item.item_name.contains('흰')) color = 'white';
      else if (item.item_name.contains('복숭아')) color = 'peach';
      

      
      if (variant == 'small_paddles') {
        imagePath = 'assets/images/garden/flowers/big_paddle/${color}_small_paddles.png';
      } else if (variant == 'big_paddles') {
        imagePath = 'assets/images/garden/flowers/big_paddle/${color}_big_paddles.png';
      }
    }
    // 부시의 경우 방향별 이미지
    else if (item.item_name.contains('부시')) {
      String color = 'light_green'; // 기본값
      if (item.item_name.contains('연한 초록')) color = 'light_green';
      else if (item.item_name.contains('초록') && !item.item_name.contains('이끼')) color = 'green';
      else if (item.item_name.contains('이끼 초록') && !item.item_name.contains('어두운')) color = 'moss_green';
      else if (item.item_name.contains('어두운 이끼')) color = 'dark_moss_green';
      
      // 모든 방향에 대한 매핑
      if (variant == 'horizontal') {
        imagePath = 'assets/images/garden/bushes/bush/$color/horizontal_regular.png';
      } else if (variant == 'vertical') {
        imagePath = 'assets/images/garden/bushes/bush/$color/vertical_regular.png';
      } else if (variant == 'left') {
        imagePath = 'assets/images/garden/bushes/bush/$color/left_regular.png';
      } else if (variant == 'right') {
        imagePath = 'assets/images/garden/bushes/bush/$color/right_regular.png';
      } else if (variant == 'top') {
        imagePath = 'assets/images/garden/bushes/bush/$color/top_regular.png';
      } else if (variant == 'bottom') {
        imagePath = 'assets/images/garden/bushes/bush/$color/bottom_regular.png';
      } else if (variant == 'top_left') {
        imagePath = 'assets/images/garden/bushes/bush/$color/top_left_regular.png';
      } else if (variant == 'top_right') {
        imagePath = 'assets/images/garden/bushes/bush/$color/top_right_regular.png';
      } else if (variant == 'bottom_left') {
        imagePath = 'assets/images/garden/bushes/bush/$color/bottom_left_regular.png';
      } else if (variant == 'bottom_right') {
        imagePath = 'assets/images/garden/bushes/bush/$color/bottom_right_regular.png';
      }
    }
    // 울타리의 경우 방향별 이미지
    else if (item.item_name.contains('울타리')) {
      String color = 'light_wood'; // 기본값
      if (item.item_name.contains('흰색')) color = 'white';
      else if (item.item_name.contains('연한 나무')) color = 'light_wood';
      

      
      if (variant == 'horizontal') {
        imagePath = 'assets/images/garden/fence/$color/Direction=↔️ Horizontal, Color=${color == 'white' ? 'White' : 'Light Wood'}.png';
      } else if (variant == 'vertical') {
        imagePath = 'assets/images/garden/fence/$color/Direction=↕️ Vertical, Color=${color == 'white' ? 'White' : 'Light Wood'}.png';
      } else if (variant == 'left') {
        imagePath = 'assets/images/garden/fence/$color/Direction=⬅️ Left, Color=${color == 'white' ? 'White' : 'Light Wood'}.png';
      } else if (variant == 'right') {
        imagePath = 'assets/images/garden/fence/$color/Direction=➡️ Right, Color=${color == 'white' ? 'White' : 'Light Wood'}.png';
      } else if (variant == 'top') {
        imagePath = 'assets/images/garden/fence/$color/Direction=⬆️ Top, Color=${color == 'white' ? 'White' : 'Light Wood'}.png';
      } else if (variant == 'bottom') {
        imagePath = 'assets/images/garden/fence/$color/Direction=⬇️ Bottom, Color=${color == 'white' ? 'White' : 'Light Wood'}.png';
      } else if (variant == 'top_left') {
        imagePath = 'assets/images/garden/fence/$color/Direction=↖️Top Left, Color=${color == 'white' ? 'White' : 'Light Wood'}.png';
      } else if (variant == 'top_right') {
        imagePath = 'assets/images/garden/fence/$color/Direction=↗️ Top Right, Color=${color == 'white' ? 'White' : 'Light Wood'}.png';
      } else if (variant == 'bottom_left') {
        imagePath = 'assets/images/garden/fence/$color/Direction=↙️ Bottom Left, Color=${color == 'white' ? 'White' : 'Light Wood'}.png';
      } else if (variant == 'bottom_right') {
        imagePath = 'assets/images/garden/fence/$color/Direction=↘️ Bottom Right, Color=${color == 'white' ? 'White' : 'Light Wood'}.png';
      }
    }
    // 나무 다리의 경우 방향별 이미지
    else if (item.item_name.contains('다리')) {
      // print('다리 방향 선택: $variant'); // 디버깅용 로그 추가
      // print('다리 아이템 이름: ${item.item_name}'); // 추가 디버깅
      
      if (variant == 'horizontal') {
        imagePath = 'assets/images/garden/bridge/bridge_horizontal.png';
      } else if (variant == 'vertical') {
        imagePath = 'assets/images/garden/bridge/bridge_vertical.png';
      } else if (variant == 'left') {
        imagePath = 'assets/images/garden/bridge/bridge_left.png';
      } else if (variant == 'right') {
        imagePath = 'assets/images/garden/bridge/bridge_right.png';
      } else if (variant == 'top') {
        imagePath = 'assets/images/garden/bridge/bridge_top.png';
      } else if (variant == 'bottom') {
        imagePath = 'assets/images/garden/bridge/bridge_bottom.png';
      } else if (variant == 'left_short') {
        imagePath = 'assets/images/garden/bridge/bridge_left_short.png';
      } else if (variant == 'right_short') {
        imagePath = 'assets/images/garden/bridge/bridge_right_short.png';
      } else if (variant == 'top_short') {
        imagePath = 'assets/images/garden/bridge/bridge_top_short.png';
      } else if (variant == 'bottom_short') {
        imagePath = 'assets/images/garden/bridge/bridge_bottom_short.png';
      }
      
      print('다리 이미지 경로: $imagePath'); // 디버깅용 로그 추가
      
      // 이미지 경로가 설정되었는지 확인
      if (imagePath != null) {
        print('다리 이미지 경로 설정 완료: $imagePath');
      } else {
        print('다리 이미지 경로 설정 실패');
      }
    }
    // 연못의 경우 위치별 이미지
    else if (item.item_name.contains('연못') && !item.item_name.contains('테두리')) {
      if (variant == 'center') {
        imagePath = 'assets/images/garden/pond/pond/Direction=🔄 Center.png';
      } else if (variant == 'top_left') {
        imagePath = 'assets/images/garden/pond/pond/Direction=↖️ Top Left.png';
      } else if (variant == 'top_right') {
        imagePath = 'assets/images/garden/pond/pond/Direction=↗️ Top Right.png';
      } else if (variant == 'bottom_left') {
        imagePath = 'assets/images/garden/pond/pond/Direction=↙️ Bottom Left.png';
      } else if (variant == 'bottom_right') {
        imagePath = 'assets/images/garden/pond/pond/Direction=↘️ Bottom Right.png';
      } else if (variant == 'left') {
        imagePath = 'assets/images/garden/pond/pond/Direction=⬅️ Left.png';
      } else if (variant == 'right') {
        imagePath = 'assets/images/garden/pond/pond/Direction=➡️ Right.png';
      } else if (variant == 'top') {
        imagePath = 'assets/images/garden/pond/pond/Direction=⬆️ Top.png';
      } else if (variant == 'bottom') {
        imagePath = 'assets/images/garden/pond/pond/Direction=⬇️ Bottom.png';
      }
    }
    // 연꽃의 경우 색상별 이미지
    else if (item.item_name.contains('연꽃')) {
      if (variant == 'light_green') {
        imagePath = 'assets/images/garden/lotus/light_green.png';
      } else if (variant == 'green') {
        imagePath = 'assets/images/garden/lotus/green.png';
      } else if (variant == 'moss_green') {
        imagePath = 'assets/images/garden/lotus/moss_green.png';
      } else if (variant == 'dark_moss_green') {
        imagePath = 'assets/images/garden/lotus/dark_moss_green.png';
      }
    }
    // 꽃봉오리 (Bloom)의 경우 크기별 이미지
    else if (item.item_name.contains('꽃봉오리')) {
      String color = 'Yellow'; // 기본값
      if (item.item_name.contains('노란')) color = 'Yellow';
      else if (item.item_name.contains('보라')) color = 'Purple';
      else if (item.item_name.contains('분홍')) color = 'Pink';
      else if (item.item_name.contains('복숭아')) color = 'Peach';
      
      if (variant == 'bud') {
        imagePath = 'assets/images/garden/bloom/color/Size=Bud, Color=$color.png';
      } else if (variant == 'big_bud') {
        imagePath = 'assets/images/garden/bloom/color/Size=Big Bud, Color=$color.png';
      } else if (variant == 'flower') {
        imagePath = 'assets/images/garden/bloom/color/Size=Flower, Color=$color.png';
      }
    }
    // 연못 테두리의 경우 방향별 이미지
    else if (item.item_name.contains('연못 테두리')) {
      String color = 'green'; // 기본값
      if (item.item_name.contains('초록')) color = 'green';
      else if (item.item_name.contains('연한 초록')) color = 'light_green';
      else if (item.item_name.contains('회색')) color = 'grey';
      else if (item.item_name.contains('어두운 회색')) color = 'dark_grey';
      
      String colorName = 'Green';
      if (color == 'light_green') colorName = 'Light Green';
      else if (color == 'grey') colorName = 'Grey';
      else if (color == 'dark_grey') colorName = 'Dark Grey';
      
      if (variant == 'left') {
        imagePath = 'assets/images/garden/pond/pond_borders/$color/Border Option=🌳 Bush, Color=$colorName, Direction=⬅️ Left.png';
      } else if (variant == 'right') {
        imagePath = 'assets/images/garden/pond/pond_borders/$color/Border Option=🌳 Bush, Color=$colorName, Direction=➡️ Right.png';
      } else if (variant == 'top') {
        imagePath = 'assets/images/garden/pond/pond_borders/$color/Border Option=🌳 Bush, Color=$colorName, Direction=⬆️ Top.png';
      } else if (variant == 'bottom') {
        imagePath = 'assets/images/garden/pond/pond_borders/$color/Border Option=🌳 Bush, Color=$colorName, Direction=⬇️ Bottom.png';
      } else if (variant == 'top_left') {
        imagePath = 'assets/images/garden/pond/pond_borders/$color/Border Option=🌳 Bush, Color=$colorName, Direction=↖️Top Left.png';
      } else if (variant == 'top_right') {
        imagePath = 'assets/images/garden/pond/pond_borders/$color/Border Option=🌳 Bush, Color=$colorName, Direction=↗️ Top Right.png';
      } else if (variant == 'bottom_left') {
        imagePath = 'assets/images/garden/pond/pond_borders/$color/Border Option=🌳 Bush, Color=$colorName, Direction=↙️ Bottom Left.png';
      } else if (variant == 'bottom_right') {
        imagePath = 'assets/images/garden/pond/pond_borders/$color/Border Option=🌳 Bush, Color=$colorName, Direction=↘️ Bottom Right.png';
      }
    }
    // 채소의 경우 패들/단일 선택
    else if (['토마토', '딸기', '당근', '양파', '마늘', '오이', '체리 토마토', '무'].any((veggie) => item.item_name.contains(veggie))) {
      String veggieType = 'Tomato'; // 기본값
      if (item.item_name.contains('토마토') && !item.item_name.contains('체리')) veggieType = 'Tomato';
      else if (item.item_name.contains('딸기')) veggieType = 'Strawberry';
      else if (item.item_name.contains('당근')) veggieType = 'Carrot';
      else if (item.item_name.contains('양파')) veggieType = 'Onion';
      else if (item.item_name.contains('마늘')) veggieType = 'Garlic';
      else if (item.item_name.contains('오이')) veggieType = 'Cucumber';
      else if (item.item_name.contains('체리 토마토')) veggieType = 'Cherry Tomatoes';
      else if (item.item_name.contains('무')) veggieType = 'Radish';
      
      if (variant == 'single') {
        imagePath = 'assets/images/garden/veggie/single/Type=$veggieType.png';
      } else if (variant == 'paddle') {
        imagePath = 'assets/images/garden/veggie/veggie_option/Type=${veggieType}s.png';
      }
    }
    

    
    if (imagePath != null) {
      // print('이미지 로드 시도: $imagePath'); // 디버깅용 로그 추가
      return Image.asset(
        imagePath,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // 이미지 로드 실패 시 기본 아이콘 사용
          print('이미지 로드 실패: $imagePath, 오류: $error');
          print('스택 트레이스: $stackTrace');
          return Icon(Icons.rotate_right, size: 20);
        },
      );
    }
    

    // 기본 아이콘
    return Icon(Icons.rotate_right, size: 20);
  }

  Widget _buildItemImage(String imagePath, String itemName) {
    // 생선은 더 작게 표시
    if (itemName.contains('물고기')) {
      return Center(
        child: Image.asset(
          imagePath,
          width: 40, // 생선은 작게
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: Icon(Icons.image_not_supported, size: 16),
            );
          },
        ),
      );
    }
    
    // 꽃은 중간 크기
    if (itemName.contains('꽃') || itemName.contains('꽃봉오리')) {
      return Center(
        child: Image.asset(
          imagePath,
          width: 50, // 꽃은 중간 크기
          height: 50,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: Icon(Icons.image_not_supported, size: 16),
            );
          },
        ),
      );
    }
    
    // 기타 아이템들은 기본 크기
    return Image.asset(
      imagePath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: Icon(Icons.image_not_supported, size: 16),
        );
      },
    );
  }

  Widget _buildGardenGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isPhone = screenWidth < 400;
    
    // 화면 크기에 따라 그리드 크기 조정
    final gridHeight = isTablet ? 600.0 : (isPhone ? 400.0 : 500.0);
    final crossAxisCount = isTablet ? 8 : 6; // 태블릿에서는 더 많은 열
    final spacing = isTablet ? 3.0 : 2.0;
    
    return Container(
      height: gridHeight,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(), // 스크롤 가능하도록 변경
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.0,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        itemCount: crossAxisCount * 12, // 동적으로 계산
        itemBuilder: (context, index) {
          int x = index % crossAxisCount;
          int y = index ~/ crossAxisCount;
          
          return _buildGridCell(x, y, crossAxisCount);
        },
      ),
    );
  }

  Widget _buildGridCell(int x, int y, int crossAxisCount) {
    // 해당 위치의 모든 아이템들을 레이어 순서대로 정렬
    List<GardenItem> itemsAtPosition = _gardenItems
        .where((item) => item.position_x == x && item.position_y == y && item.is_equipped)
        .toList();
    
    // 레이어 순서대로 정렬 (0: 배경, 1: 중간, 2: 식물, 3: 동물)
    itemsAtPosition.sort((a, b) => a.layer.compareTo(b.layer));
    
    if (itemsAtPosition.isEmpty) {
      // 빈 셀 - 클릭 시 아이템 배치
      return GestureDetector(
        onTap: () {
          if (mounted && !_disposed) {
            _showInventorySelectionDialog(x, y);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF8B4513), // 진한 흙색
            border: Border.all(color: Color(0xFF654321), width: 1), // 어두운 흙색 테두리
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }
    
    // 아이템들이 있는 경우 - 레이어 순서대로 쌓기
    return GestureDetector(
      onTap: () {
        if (mounted && !_disposed) {
          // 아이템이 있는 셀을 클릭했을 때 선택 옵션 제공
          _showOccupiedCellOptions(x, y, itemsAtPosition);
        }
      },
      child: Stack(
        children: itemsAtPosition.map((item) {
          // 데이터베이스에 저장된 이미지 경로를 우선 사용
          String? imagePath = item.item_image;
          
          // 데이터베이스에 저장된 이미지가 없으면 기본 이미지 사용
          if (imagePath == null || imagePath.isEmpty) {
            imagePath = _getItemImageByName(item.item_name);
          }
          
          if (imagePath != null && imagePath.isNotEmpty) {
            return _buildItemImage(imagePath, item.item_name);
          } else {
            return _getItemWidget(item, size: 50);
          }
        }).toList(),
      ),
    );
  }



  Color _getLayerColor(int layer) {
    switch (layer) {
      case 0:
        return Colors.brown; // 배경
      case 1:
        return Colors.blue; // 중간
      case 2:
        return Colors.green; // 식물
      case 3:
        return Colors.orange; // 동물
      default:
        return Colors.grey;
    }
  }

  String _getLayerName(int layer) {
    switch (layer) {
      case 0:
        return '배경';
      case 1:
        return '중간';
      case 2:
        return '식물';
      case 3:
        return '동물';
      default:
        return '알 수 없음';
    }
  }

  void _showInventorySelectionDialog(int x, int y) {
    if (!mounted || _disposed) return;
    
    // 배치되지 않은 아이템들만 필터링하고 그룹화
    Map<String, List<GardenItem>> groupedItems = {};
    
    for (var item in _inventoryItems) {
      String key = '${item.item_name}';
      if (!groupedItems.containsKey(key)) {
        groupedItems[key] = [];
      }
      groupedItems[key]!.add(item);
    }
    
    List<MapEntry<String, List<GardenItem>>> sortedItems = groupedItems.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('아이템 선택'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: sortedItems.length,
            itemBuilder: (context, index) {
              final entry = sortedItems[index];
              final itemName = entry.key;
              final items = entry.value;
              final count = items.length;
              final firstItem = items.first;
              
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  child: _getItemWidget(firstItem, size: 32),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemName,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count개',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${firstItem.item_type}',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getLayerColor(firstItem.layer),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getLayerName(firstItem.layer),
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  if (mounted && !_disposed) {
                    _showDirectionSelectionDialog(firstItem, x, y);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _showOccupiedCellOptions(int x, int y, List<GardenItem> itemsAtPosition) {
    if (!mounted || _disposed) return;

    // 가장 위에 있는 아이템
    GardenItem topItem = itemsAtPosition.last;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('셀 옵션'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 현재 배치된 아이템들 표시
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    '현재 배치된 아이템들:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...itemsAtPosition.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          child: _getItemWidget(item, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item.item_name} (${_getLayerName(item.layer)})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '이 위치에서 무엇을 하시겠습니까?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted && !_disposed) {
                // 새 아이템 배치
                _showInventorySelectionDialog(x, y);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('새 아이템 배치'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (mounted && !_disposed) {
                // 가장 위에 있는 아이템 제거
                _removeItem(topItem.id);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('아이템 제거'),
          ),
        ],
      ),
    );
  }
} 