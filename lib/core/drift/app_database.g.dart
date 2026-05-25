// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductCacheTable extends ProductCache
    with TableInfo<$ProductCacheTable, ProductCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minPriceMeta = const VerificationMeta(
    'minPrice',
  );
  @override
  late final GeneratedColumn<double> minPrice = GeneratedColumn<double>(
    'min_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    updatedAt,
    sku,
    minPrice,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('min_price')) {
      context.handle(
        _minPriceMeta,
        minPrice.isAcceptableOrUnknown(data['min_price']!, _minPriceMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      minPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_price'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $ProductCacheTable createAlias(String alias) {
    return $ProductCacheTable(attachedDatabase, alias);
  }
}

class ProductCacheData extends DataClass
    implements Insertable<ProductCacheData> {
  final int id;
  final String name;
  final DateTime updatedAt;
  final String? sku;
  final double? minPrice;
  final bool active;
  const ProductCacheData({
    required this.id,
    required this.name,
    required this.updatedAt,
    this.sku,
    this.minPrice,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || minPrice != null) {
      map['min_price'] = Variable<double>(minPrice);
    }
    map['active'] = Variable<bool>(active);
    return map;
  }

  ProductCacheCompanion toCompanion(bool nullToAbsent) {
    return ProductCacheCompanion(
      id: Value(id),
      name: Value(name),
      updatedAt: Value(updatedAt),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      minPrice: minPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(minPrice),
      active: Value(active),
    );
  }

  factory ProductCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductCacheData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      sku: serializer.fromJson<String?>(json['sku']),
      minPrice: serializer.fromJson<double?>(json['minPrice']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'sku': serializer.toJson<String?>(sku),
      'minPrice': serializer.toJson<double?>(minPrice),
      'active': serializer.toJson<bool>(active),
    };
  }

  ProductCacheData copyWith({
    int? id,
    String? name,
    DateTime? updatedAt,
    Value<String?> sku = const Value.absent(),
    Value<double?> minPrice = const Value.absent(),
    bool? active,
  }) => ProductCacheData(
    id: id ?? this.id,
    name: name ?? this.name,
    updatedAt: updatedAt ?? this.updatedAt,
    sku: sku.present ? sku.value : this.sku,
    minPrice: minPrice.present ? minPrice.value : this.minPrice,
    active: active ?? this.active,
  );
  ProductCacheData copyWithCompanion(ProductCacheCompanion data) {
    return ProductCacheData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      sku: data.sku.present ? data.sku.value : this.sku,
      minPrice: data.minPrice.present ? data.minPrice.value : this.minPrice,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductCacheData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sku: $sku, ')
          ..write('minPrice: $minPrice, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, updatedAt, sku, minPrice, active);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductCacheData &&
          other.id == this.id &&
          other.name == this.name &&
          other.updatedAt == this.updatedAt &&
          other.sku == this.sku &&
          other.minPrice == this.minPrice &&
          other.active == this.active);
}

class ProductCacheCompanion extends UpdateCompanion<ProductCacheData> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> updatedAt;
  final Value<String?> sku;
  final Value<double?> minPrice;
  final Value<bool> active;
  const ProductCacheCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.sku = const Value.absent(),
    this.minPrice = const Value.absent(),
    this.active = const Value.absent(),
  });
  ProductCacheCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime updatedAt,
    this.sku = const Value.absent(),
    this.minPrice = const Value.absent(),
    this.active = const Value.absent(),
  }) : name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<ProductCacheData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? updatedAt,
    Expression<String>? sku,
    Expression<double>? minPrice,
    Expression<bool>? active,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (sku != null) 'sku': sku,
      if (minPrice != null) 'min_price': minPrice,
      if (active != null) 'active': active,
    });
  }

  ProductCacheCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? updatedAt,
    Value<String?>? sku,
    Value<double?>? minPrice,
    Value<bool>? active,
  }) {
    return ProductCacheCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      updatedAt: updatedAt ?? this.updatedAt,
      sku: sku ?? this.sku,
      minPrice: minPrice ?? this.minPrice,
      active: active ?? this.active,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (minPrice.present) {
      map['min_price'] = Variable<double>(minPrice.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductCacheCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sku: $sku, ')
          ..write('minPrice: $minPrice, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }
}

class $BatchCacheTable extends BatchCache
    with TableInfo<$BatchCacheTable, BatchCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatchCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentStockMeta = const VerificationMeta(
    'currentStock',
  );
  @override
  late final GeneratedColumn<double> currentStock = GeneratedColumn<double>(
    'current_stock',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    currentStock,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'batch_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<BatchCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('current_stock')) {
      context.handle(
        _currentStockMeta,
        currentStock.isAcceptableOrUnknown(
          data['current_stock']!,
          _currentStockMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentStockMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BatchCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BatchCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      currentStock: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_stock'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BatchCacheTable createAlias(String alias) {
    return $BatchCacheTable(attachedDatabase, alias);
  }
}

class BatchCacheData extends DataClass implements Insertable<BatchCacheData> {
  final int id;
  final int productId;
  final double currentStock;
  final DateTime updatedAt;
  const BatchCacheData({
    required this.id,
    required this.productId,
    required this.currentStock,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['current_stock'] = Variable<double>(currentStock);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BatchCacheCompanion toCompanion(bool nullToAbsent) {
    return BatchCacheCompanion(
      id: Value(id),
      productId: Value(productId),
      currentStock: Value(currentStock),
      updatedAt: Value(updatedAt),
    );
  }

  factory BatchCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BatchCacheData(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      currentStock: serializer.fromJson<double>(json['currentStock']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'currentStock': serializer.toJson<double>(currentStock),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BatchCacheData copyWith({
    int? id,
    int? productId,
    double? currentStock,
    DateTime? updatedAt,
  }) => BatchCacheData(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    currentStock: currentStock ?? this.currentStock,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BatchCacheData copyWithCompanion(BatchCacheCompanion data) {
    return BatchCacheData(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      currentStock: data.currentStock.present
          ? data.currentStock.value
          : this.currentStock,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BatchCacheData(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('currentStock: $currentStock, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productId, currentStock, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BatchCacheData &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.currentStock == this.currentStock &&
          other.updatedAt == this.updatedAt);
}

class BatchCacheCompanion extends UpdateCompanion<BatchCacheData> {
  final Value<int> id;
  final Value<int> productId;
  final Value<double> currentStock;
  final Value<DateTime> updatedAt;
  const BatchCacheCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.currentStock = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BatchCacheCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    required double currentStock,
    required DateTime updatedAt,
  }) : productId = Value(productId),
       currentStock = Value(currentStock),
       updatedAt = Value(updatedAt);
  static Insertable<BatchCacheData> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<double>? currentStock,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (currentStock != null) 'current_stock': currentStock,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BatchCacheCompanion copyWith({
    Value<int>? id,
    Value<int>? productId,
    Value<double>? currentStock,
    Value<DateTime>? updatedAt,
  }) {
    return BatchCacheCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      currentStock: currentStock ?? this.currentStock,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (currentStock.present) {
      map['current_stock'] = Variable<double>(currentStock.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BatchCacheCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('currentStock: $currentStock, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $InventoryCacheTable extends InventoryCache
    with TableInfo<$InventoryCacheTable, InventoryCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentStockMeta = const VerificationMeta(
    'currentStock',
  );
  @override
  late final GeneratedColumn<double> currentStock = GeneratedColumn<double>(
    'current_stock',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minStockThresholdMeta = const VerificationMeta(
    'minStockThreshold',
  );
  @override
  late final GeneratedColumn<double> minStockThreshold =
      GeneratedColumn<double>(
        'min_stock_threshold',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    productName,
    currentStock,
    minStockThreshold,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('current_stock')) {
      context.handle(
        _currentStockMeta,
        currentStock.isAcceptableOrUnknown(
          data['current_stock']!,
          _currentStockMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentStockMeta);
    }
    if (data.containsKey('min_stock_threshold')) {
      context.handle(
        _minStockThresholdMeta,
        minStockThreshold.isAcceptableOrUnknown(
          data['min_stock_threshold']!,
          _minStockThresholdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minStockThresholdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId};
  @override
  InventoryCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryCacheData(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      currentStock: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_stock'],
      )!,
      minStockThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_stock_threshold'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InventoryCacheTable createAlias(String alias) {
    return $InventoryCacheTable(attachedDatabase, alias);
  }
}

class InventoryCacheData extends DataClass
    implements Insertable<InventoryCacheData> {
  final int productId;
  final String productName;
  final double currentStock;
  final double minStockThreshold;
  final DateTime updatedAt;
  const InventoryCacheData({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.minStockThreshold,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<int>(productId);
    map['product_name'] = Variable<String>(productName);
    map['current_stock'] = Variable<double>(currentStock);
    map['min_stock_threshold'] = Variable<double>(minStockThreshold);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InventoryCacheCompanion toCompanion(bool nullToAbsent) {
    return InventoryCacheCompanion(
      productId: Value(productId),
      productName: Value(productName),
      currentStock: Value(currentStock),
      minStockThreshold: Value(minStockThreshold),
      updatedAt: Value(updatedAt),
    );
  }

  factory InventoryCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryCacheData(
      productId: serializer.fromJson<int>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      currentStock: serializer.fromJson<double>(json['currentStock']),
      minStockThreshold: serializer.fromJson<double>(json['minStockThreshold']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<int>(productId),
      'productName': serializer.toJson<String>(productName),
      'currentStock': serializer.toJson<double>(currentStock),
      'minStockThreshold': serializer.toJson<double>(minStockThreshold),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InventoryCacheData copyWith({
    int? productId,
    String? productName,
    double? currentStock,
    double? minStockThreshold,
    DateTime? updatedAt,
  }) => InventoryCacheData(
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    currentStock: currentStock ?? this.currentStock,
    minStockThreshold: minStockThreshold ?? this.minStockThreshold,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InventoryCacheData copyWithCompanion(InventoryCacheCompanion data) {
    return InventoryCacheData(
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      currentStock: data.currentStock.present
          ? data.currentStock.value
          : this.currentStock,
      minStockThreshold: data.minStockThreshold.present
          ? data.minStockThreshold.value
          : this.minStockThreshold,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryCacheData(')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('currentStock: $currentStock, ')
          ..write('minStockThreshold: $minStockThreshold, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    productId,
    productName,
    currentStock,
    minStockThreshold,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryCacheData &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.currentStock == this.currentStock &&
          other.minStockThreshold == this.minStockThreshold &&
          other.updatedAt == this.updatedAt);
}

class InventoryCacheCompanion extends UpdateCompanion<InventoryCacheData> {
  final Value<int> productId;
  final Value<String> productName;
  final Value<double> currentStock;
  final Value<double> minStockThreshold;
  final Value<DateTime> updatedAt;
  const InventoryCacheCompanion({
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.currentStock = const Value.absent(),
    this.minStockThreshold = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  InventoryCacheCompanion.insert({
    this.productId = const Value.absent(),
    required String productName,
    required double currentStock,
    required double minStockThreshold,
    required DateTime updatedAt,
  }) : productName = Value(productName),
       currentStock = Value(currentStock),
       minStockThreshold = Value(minStockThreshold),
       updatedAt = Value(updatedAt);
  static Insertable<InventoryCacheData> custom({
    Expression<int>? productId,
    Expression<String>? productName,
    Expression<double>? currentStock,
    Expression<double>? minStockThreshold,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (currentStock != null) 'current_stock': currentStock,
      if (minStockThreshold != null) 'min_stock_threshold': minStockThreshold,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  InventoryCacheCompanion copyWith({
    Value<int>? productId,
    Value<String>? productName,
    Value<double>? currentStock,
    Value<double>? minStockThreshold,
    Value<DateTime>? updatedAt,
  }) {
    return InventoryCacheCompanion(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      currentStock: currentStock ?? this.currentStock,
      minStockThreshold: minStockThreshold ?? this.minStockThreshold,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (currentStock.present) {
      map['current_stock'] = Variable<double>(currentStock.value);
    }
    if (minStockThreshold.present) {
      map['min_stock_threshold'] = Variable<double>(minStockThreshold.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryCacheCompanion(')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('currentStock: $currentStock, ')
          ..write('minStockThreshold: $minStockThreshold, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DraftSalesTable extends DraftSales
    with TableInfo<$DraftSalesTable, DraftSale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftSalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<int> batchId = GeneratedColumn<int>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    productName,
    batchId,
    quantity,
    unitPrice,
    status,
    createdAt,
    confirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'draft_sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<DraftSale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DraftSale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftSale(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batch_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      ),
    );
  }

  @override
  $DraftSalesTable createAlias(String alias) {
    return $DraftSalesTable(attachedDatabase, alias);
  }
}

class DraftSale extends DataClass implements Insertable<DraftSale> {
  final int id;
  final int productId;
  final String productName;
  final int batchId;
  final double quantity;
  final double unitPrice;
  final String status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  const DraftSale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.batchId,
    required this.quantity,
    required this.unitPrice,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['product_name'] = Variable<String>(productName);
    map['batch_id'] = Variable<int>(batchId);
    map['quantity'] = Variable<double>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    }
    return map;
  }

  DraftSalesCompanion toCompanion(bool nullToAbsent) {
    return DraftSalesCompanion(
      id: Value(id),
      productId: Value(productId),
      productName: Value(productName),
      batchId: Value(batchId),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      status: Value(status),
      createdAt: Value(createdAt),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
    );
  }

  factory DraftSale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftSale(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      batchId: serializer.fromJson<int>(json['batchId']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      confirmedAt: serializer.fromJson<DateTime?>(json['confirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'productName': serializer.toJson<String>(productName),
      'batchId': serializer.toJson<int>(batchId),
      'quantity': serializer.toJson<double>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'confirmedAt': serializer.toJson<DateTime?>(confirmedAt),
    };
  }

  DraftSale copyWith({
    int? id,
    int? productId,
    String? productName,
    int? batchId,
    double? quantity,
    double? unitPrice,
    String? status,
    DateTime? createdAt,
    Value<DateTime?> confirmedAt = const Value.absent(),
  }) => DraftSale(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    batchId: batchId ?? this.batchId,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
  );
  DraftSale copyWithCompanion(DraftSalesCompanion data) {
    return DraftSale(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftSale(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('batchId: $batchId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    productName,
    batchId,
    quantity,
    unitPrice,
    status,
    createdAt,
    confirmedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftSale &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.batchId == this.batchId &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.confirmedAt == this.confirmedAt);
}

class DraftSalesCompanion extends UpdateCompanion<DraftSale> {
  final Value<int> id;
  final Value<int> productId;
  final Value<String> productName;
  final Value<int> batchId;
  final Value<double> quantity;
  final Value<double> unitPrice;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime?> confirmedAt;
  const DraftSalesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.batchId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
  });
  DraftSalesCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    required String productName,
    required int batchId,
    required double quantity,
    required double unitPrice,
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
  }) : productId = Value(productId),
       productName = Value(productName),
       batchId = Value(batchId),
       quantity = Value(quantity),
       unitPrice = Value(unitPrice);
  static Insertable<DraftSale> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<String>? productName,
    Expression<int>? batchId,
    Expression<double>? quantity,
    Expression<double>? unitPrice,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? confirmedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (batchId != null) 'batch_id': batchId,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
    });
  }

  DraftSalesCompanion copyWith({
    Value<int>? id,
    Value<int>? productId,
    Value<String>? productName,
    Value<int>? batchId,
    Value<double>? quantity,
    Value<double>? unitPrice,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime?>? confirmedAt,
  }) {
    return DraftSalesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      batchId: batchId ?? this.batchId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<int>(batchId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftSalesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('batchId: $batchId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }
}

class $InventoryPendingQueueTable extends InventoryPendingQueue
    with TableInfo<$InventoryPendingQueueTable, InventoryPendingQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryPendingQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    payload,
    status,
    createdAt,
    errorMessage,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_pending_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryPendingQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryPendingQueueData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryPendingQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $InventoryPendingQueueTable createAlias(String alias) {
    return $InventoryPendingQueueTable(attachedDatabase, alias);
  }
}

class InventoryPendingQueueData extends DataClass
    implements Insertable<InventoryPendingQueueData> {
  final int id;
  final int productId;
  final String payload;
  final String status;
  final DateTime createdAt;
  final String? errorMessage;
  final int retryCount;
  const InventoryPendingQueueData({
    required this.id,
    required this.productId,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.errorMessage,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_id'] = Variable<int>(productId);
    map['payload'] = Variable<String>(payload);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  InventoryPendingQueueCompanion toCompanion(bool nullToAbsent) {
    return InventoryPendingQueueCompanion(
      id: Value(id),
      productId: Value(productId),
      payload: Value(payload),
      status: Value(status),
      createdAt: Value(createdAt),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      retryCount: Value(retryCount),
    );
  }

  factory InventoryPendingQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryPendingQueueData(
      id: serializer.fromJson<int>(json['id']),
      productId: serializer.fromJson<int>(json['productId']),
      payload: serializer.fromJson<String>(json['payload']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productId': serializer.toJson<int>(productId),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  InventoryPendingQueueData copyWith({
    int? id,
    int? productId,
    String? payload,
    String? status,
    DateTime? createdAt,
    Value<String?> errorMessage = const Value.absent(),
    int? retryCount,
  }) => InventoryPendingQueueData(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    retryCount: retryCount ?? this.retryCount,
  );
  InventoryPendingQueueData copyWithCompanion(
    InventoryPendingQueueCompanion data,
  ) {
    return InventoryPendingQueueData(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryPendingQueueData(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    payload,
    status,
    createdAt,
    errorMessage,
    retryCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryPendingQueueData &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.errorMessage == this.errorMessage &&
          other.retryCount == this.retryCount);
}

class InventoryPendingQueueCompanion
    extends UpdateCompanion<InventoryPendingQueueData> {
  final Value<int> id;
  final Value<int> productId;
  final Value<String> payload;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<String?> errorMessage;
  final Value<int> retryCount;
  const InventoryPendingQueueCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.retryCount = const Value.absent(),
  });
  InventoryPendingQueueCompanion.insert({
    this.id = const Value.absent(),
    required int productId,
    required String payload,
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.retryCount = const Value.absent(),
  }) : productId = Value(productId),
       payload = Value(payload);
  static Insertable<InventoryPendingQueueData> custom({
    Expression<int>? id,
    Expression<int>? productId,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<String>? errorMessage,
    Expression<int>? retryCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (errorMessage != null) 'error_message': errorMessage,
      if (retryCount != null) 'retry_count': retryCount,
    });
  }

  InventoryPendingQueueCompanion copyWith({
    Value<int>? id,
    Value<int>? productId,
    Value<String>? payload,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<String?>? errorMessage,
    Value<int>? retryCount,
  }) {
    return InventoryPendingQueueCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryPendingQueueCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductCacheTable productCache = $ProductCacheTable(this);
  late final $BatchCacheTable batchCache = $BatchCacheTable(this);
  late final $InventoryCacheTable inventoryCache = $InventoryCacheTable(this);
  late final $DraftSalesTable draftSales = $DraftSalesTable(this);
  late final $InventoryPendingQueueTable inventoryPendingQueue =
      $InventoryPendingQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    productCache,
    batchCache,
    inventoryCache,
    draftSales,
    inventoryPendingQueue,
  ];
}

typedef $$ProductCacheTableCreateCompanionBuilder =
    ProductCacheCompanion Function({
      Value<int> id,
      required String name,
      required DateTime updatedAt,
      Value<String?> sku,
      Value<double?> minPrice,
      Value<bool> active,
    });
typedef $$ProductCacheTableUpdateCompanionBuilder =
    ProductCacheCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> updatedAt,
      Value<String?> sku,
      Value<double?> minPrice,
      Value<bool> active,
    });

class $$ProductCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ProductCacheTable> {
  $$ProductCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minPrice => $composableBuilder(
    column: $table.minPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductCacheTable> {
  $$ProductCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minPrice => $composableBuilder(
    column: $table.minPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductCacheTable> {
  $$ProductCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<double> get minPrice =>
      $composableBuilder(column: $table.minPrice, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);
}

class $$ProductCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductCacheTable,
          ProductCacheData,
          $$ProductCacheTableFilterComposer,
          $$ProductCacheTableOrderingComposer,
          $$ProductCacheTableAnnotationComposer,
          $$ProductCacheTableCreateCompanionBuilder,
          $$ProductCacheTableUpdateCompanionBuilder,
          (
            ProductCacheData,
            BaseReferences<_$AppDatabase, $ProductCacheTable, ProductCacheData>,
          ),
          ProductCacheData,
          PrefetchHooks Function()
        > {
  $$ProductCacheTableTableManager(_$AppDatabase db, $ProductCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<double?> minPrice = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => ProductCacheCompanion(
                id: id,
                name: name,
                updatedAt: updatedAt,
                sku: sku,
                minPrice: minPrice,
                active: active,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required DateTime updatedAt,
                Value<String?> sku = const Value.absent(),
                Value<double?> minPrice = const Value.absent(),
                Value<bool> active = const Value.absent(),
              }) => ProductCacheCompanion.insert(
                id: id,
                name: name,
                updatedAt: updatedAt,
                sku: sku,
                minPrice: minPrice,
                active: active,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductCacheTable,
      ProductCacheData,
      $$ProductCacheTableFilterComposer,
      $$ProductCacheTableOrderingComposer,
      $$ProductCacheTableAnnotationComposer,
      $$ProductCacheTableCreateCompanionBuilder,
      $$ProductCacheTableUpdateCompanionBuilder,
      (
        ProductCacheData,
        BaseReferences<_$AppDatabase, $ProductCacheTable, ProductCacheData>,
      ),
      ProductCacheData,
      PrefetchHooks Function()
    >;
typedef $$BatchCacheTableCreateCompanionBuilder =
    BatchCacheCompanion Function({
      Value<int> id,
      required int productId,
      required double currentStock,
      required DateTime updatedAt,
    });
typedef $$BatchCacheTableUpdateCompanionBuilder =
    BatchCacheCompanion Function({
      Value<int> id,
      Value<int> productId,
      Value<double> currentStock,
      Value<DateTime> updatedAt,
    });

class $$BatchCacheTableFilterComposer
    extends Composer<_$AppDatabase, $BatchCacheTable> {
  $$BatchCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BatchCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $BatchCacheTable> {
  $$BatchCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BatchCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatchCacheTable> {
  $$BatchCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<double> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BatchCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchCacheTable,
          BatchCacheData,
          $$BatchCacheTableFilterComposer,
          $$BatchCacheTableOrderingComposer,
          $$BatchCacheTableAnnotationComposer,
          $$BatchCacheTableCreateCompanionBuilder,
          $$BatchCacheTableUpdateCompanionBuilder,
          (
            BatchCacheData,
            BaseReferences<_$AppDatabase, $BatchCacheTable, BatchCacheData>,
          ),
          BatchCacheData,
          PrefetchHooks Function()
        > {
  $$BatchCacheTableTableManager(_$AppDatabase db, $BatchCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatchCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BatchCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BatchCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<double> currentStock = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BatchCacheCompanion(
                id: id,
                productId: productId,
                currentStock: currentStock,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productId,
                required double currentStock,
                required DateTime updatedAt,
              }) => BatchCacheCompanion.insert(
                id: id,
                productId: productId,
                currentStock: currentStock,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BatchCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatchCacheTable,
      BatchCacheData,
      $$BatchCacheTableFilterComposer,
      $$BatchCacheTableOrderingComposer,
      $$BatchCacheTableAnnotationComposer,
      $$BatchCacheTableCreateCompanionBuilder,
      $$BatchCacheTableUpdateCompanionBuilder,
      (
        BatchCacheData,
        BaseReferences<_$AppDatabase, $BatchCacheTable, BatchCacheData>,
      ),
      BatchCacheData,
      PrefetchHooks Function()
    >;
typedef $$InventoryCacheTableCreateCompanionBuilder =
    InventoryCacheCompanion Function({
      Value<int> productId,
      required String productName,
      required double currentStock,
      required double minStockThreshold,
      required DateTime updatedAt,
    });
typedef $$InventoryCacheTableUpdateCompanionBuilder =
    InventoryCacheCompanion Function({
      Value<int> productId,
      Value<String> productName,
      Value<double> currentStock,
      Value<double> minStockThreshold,
      Value<DateTime> updatedAt,
    });

class $$InventoryCacheTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryCacheTable> {
  $$InventoryCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minStockThreshold => $composableBuilder(
    column: $table.minStockThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryCacheTable> {
  $$InventoryCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minStockThreshold => $composableBuilder(
    column: $table.minStockThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryCacheTable> {
  $$InventoryCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minStockThreshold => $composableBuilder(
    column: $table.minStockThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InventoryCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryCacheTable,
          InventoryCacheData,
          $$InventoryCacheTableFilterComposer,
          $$InventoryCacheTableOrderingComposer,
          $$InventoryCacheTableAnnotationComposer,
          $$InventoryCacheTableCreateCompanionBuilder,
          $$InventoryCacheTableUpdateCompanionBuilder,
          (
            InventoryCacheData,
            BaseReferences<
              _$AppDatabase,
              $InventoryCacheTable,
              InventoryCacheData
            >,
          ),
          InventoryCacheData,
          PrefetchHooks Function()
        > {
  $$InventoryCacheTableTableManager(
    _$AppDatabase db,
    $InventoryCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<double> currentStock = const Value.absent(),
                Value<double> minStockThreshold = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => InventoryCacheCompanion(
                productId: productId,
                productName: productName,
                currentStock: currentStock,
                minStockThreshold: minStockThreshold,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> productId = const Value.absent(),
                required String productName,
                required double currentStock,
                required double minStockThreshold,
                required DateTime updatedAt,
              }) => InventoryCacheCompanion.insert(
                productId: productId,
                productName: productName,
                currentStock: currentStock,
                minStockThreshold: minStockThreshold,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryCacheTable,
      InventoryCacheData,
      $$InventoryCacheTableFilterComposer,
      $$InventoryCacheTableOrderingComposer,
      $$InventoryCacheTableAnnotationComposer,
      $$InventoryCacheTableCreateCompanionBuilder,
      $$InventoryCacheTableUpdateCompanionBuilder,
      (
        InventoryCacheData,
        BaseReferences<_$AppDatabase, $InventoryCacheTable, InventoryCacheData>,
      ),
      InventoryCacheData,
      PrefetchHooks Function()
    >;
typedef $$DraftSalesTableCreateCompanionBuilder =
    DraftSalesCompanion Function({
      Value<int> id,
      required int productId,
      required String productName,
      required int batchId,
      required double quantity,
      required double unitPrice,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> confirmedAt,
    });
typedef $$DraftSalesTableUpdateCompanionBuilder =
    DraftSalesCompanion Function({
      Value<int> id,
      Value<int> productId,
      Value<String> productName,
      Value<int> batchId,
      Value<double> quantity,
      Value<double> unitPrice,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime?> confirmedAt,
    });

class $$DraftSalesTableFilterComposer
    extends Composer<_$AppDatabase, $DraftSalesTable> {
  $$DraftSalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftSalesTable> {
  $$DraftSalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftSalesTable> {
  $$DraftSalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );
}

class $$DraftSalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DraftSalesTable,
          DraftSale,
          $$DraftSalesTableFilterComposer,
          $$DraftSalesTableOrderingComposer,
          $$DraftSalesTableAnnotationComposer,
          $$DraftSalesTableCreateCompanionBuilder,
          $$DraftSalesTableUpdateCompanionBuilder,
          (
            DraftSale,
            BaseReferences<_$AppDatabase, $DraftSalesTable, DraftSale>,
          ),
          DraftSale,
          PrefetchHooks Function()
        > {
  $$DraftSalesTableTableManager(_$AppDatabase db, $DraftSalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<int> batchId = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
              }) => DraftSalesCompanion(
                id: id,
                productId: productId,
                productName: productName,
                batchId: batchId,
                quantity: quantity,
                unitPrice: unitPrice,
                status: status,
                createdAt: createdAt,
                confirmedAt: confirmedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productId,
                required String productName,
                required int batchId,
                required double quantity,
                required double unitPrice,
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
              }) => DraftSalesCompanion.insert(
                id: id,
                productId: productId,
                productName: productName,
                batchId: batchId,
                quantity: quantity,
                unitPrice: unitPrice,
                status: status,
                createdAt: createdAt,
                confirmedAt: confirmedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftSalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DraftSalesTable,
      DraftSale,
      $$DraftSalesTableFilterComposer,
      $$DraftSalesTableOrderingComposer,
      $$DraftSalesTableAnnotationComposer,
      $$DraftSalesTableCreateCompanionBuilder,
      $$DraftSalesTableUpdateCompanionBuilder,
      (DraftSale, BaseReferences<_$AppDatabase, $DraftSalesTable, DraftSale>),
      DraftSale,
      PrefetchHooks Function()
    >;
typedef $$InventoryPendingQueueTableCreateCompanionBuilder =
    InventoryPendingQueueCompanion Function({
      Value<int> id,
      required int productId,
      required String payload,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<String?> errorMessage,
      Value<int> retryCount,
    });
typedef $$InventoryPendingQueueTableUpdateCompanionBuilder =
    InventoryPendingQueueCompanion Function({
      Value<int> id,
      Value<int> productId,
      Value<String> payload,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<String?> errorMessage,
      Value<int> retryCount,
    });

class $$InventoryPendingQueueTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryPendingQueueTable> {
  $$InventoryPendingQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryPendingQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryPendingQueueTable> {
  $$InventoryPendingQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryPendingQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryPendingQueueTable> {
  $$InventoryPendingQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$InventoryPendingQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryPendingQueueTable,
          InventoryPendingQueueData,
          $$InventoryPendingQueueTableFilterComposer,
          $$InventoryPendingQueueTableOrderingComposer,
          $$InventoryPendingQueueTableAnnotationComposer,
          $$InventoryPendingQueueTableCreateCompanionBuilder,
          $$InventoryPendingQueueTableUpdateCompanionBuilder,
          (
            InventoryPendingQueueData,
            BaseReferences<
              _$AppDatabase,
              $InventoryPendingQueueTable,
              InventoryPendingQueueData
            >,
          ),
          InventoryPendingQueueData,
          PrefetchHooks Function()
        > {
  $$InventoryPendingQueueTableTableManager(
    _$AppDatabase db,
    $InventoryPendingQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryPendingQueueTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InventoryPendingQueueTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InventoryPendingQueueTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> productId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => InventoryPendingQueueCompanion(
                id: id,
                productId: productId,
                payload: payload,
                status: status,
                createdAt: createdAt,
                errorMessage: errorMessage,
                retryCount: retryCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int productId,
                required String payload,
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
              }) => InventoryPendingQueueCompanion.insert(
                id: id,
                productId: productId,
                payload: payload,
                status: status,
                createdAt: createdAt,
                errorMessage: errorMessage,
                retryCount: retryCount,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryPendingQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryPendingQueueTable,
      InventoryPendingQueueData,
      $$InventoryPendingQueueTableFilterComposer,
      $$InventoryPendingQueueTableOrderingComposer,
      $$InventoryPendingQueueTableAnnotationComposer,
      $$InventoryPendingQueueTableCreateCompanionBuilder,
      $$InventoryPendingQueueTableUpdateCompanionBuilder,
      (
        InventoryPendingQueueData,
        BaseReferences<
          _$AppDatabase,
          $InventoryPendingQueueTable,
          InventoryPendingQueueData
        >,
      ),
      InventoryPendingQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductCacheTableTableManager get productCache =>
      $$ProductCacheTableTableManager(_db, _db.productCache);
  $$BatchCacheTableTableManager get batchCache =>
      $$BatchCacheTableTableManager(_db, _db.batchCache);
  $$InventoryCacheTableTableManager get inventoryCache =>
      $$InventoryCacheTableTableManager(_db, _db.inventoryCache);
  $$DraftSalesTableTableManager get draftSales =>
      $$DraftSalesTableTableManager(_db, _db.draftSales);
  $$InventoryPendingQueueTableTableManager get inventoryPendingQueue =>
      $$InventoryPendingQueueTableTableManager(_db, _db.inventoryPendingQueue);
}
