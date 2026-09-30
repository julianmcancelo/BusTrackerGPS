// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LinesTable extends Lines with TableInfo<$LinesTable, LineEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LinesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<String> number = GeneratedColumn<String>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    number,
    name,
    active,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<LineEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    } else if (isInserting) {
      context.missing(_numberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LineEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LineEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LinesTable createAlias(String alias) {
    return $LinesTable(attachedDatabase, alias);
  }
}

class LineEntry extends DataClass implements Insertable<LineEntry> {
  final int id;
  final String number;
  final String name;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LineEntry({
    required this.id,
    required this.number,
    required this.name,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['number'] = Variable<String>(number);
    map['name'] = Variable<String>(name);
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LinesCompanion toCompanion(bool nullToAbsent) {
    return LinesCompanion(
      id: Value(id),
      number: Value(number),
      name: Value(name),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LineEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LineEntry(
      id: serializer.fromJson<int>(json['id']),
      number: serializer.fromJson<String>(json['number']),
      name: serializer.fromJson<String>(json['name']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'number': serializer.toJson<String>(number),
      'name': serializer.toJson<String>(name),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LineEntry copyWith({
    int? id,
    String? number,
    String? name,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LineEntry(
    id: id ?? this.id,
    number: number ?? this.number,
    name: name ?? this.name,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LineEntry copyWithCompanion(LinesCompanion data) {
    return LineEntry(
      id: data.id.present ? data.id.value : this.id,
      number: data.number.present ? data.number.value : this.number,
      name: data.name.present ? data.name.value : this.name,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LineEntry(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('name: $name, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, number, name, active, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LineEntry &&
          other.id == this.id &&
          other.number == this.number &&
          other.name == this.name &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LinesCompanion extends UpdateCompanion<LineEntry> {
  final Value<int> id;
  final Value<String> number;
  final Value<String> name;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const LinesCompanion({
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.name = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LinesCompanion.insert({
    this.id = const Value.absent(),
    required String number,
    required String name,
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : number = Value(number),
       name = Value(name);
  static Insertable<LineEntry> custom({
    Expression<int>? id,
    Expression<String>? number,
    Expression<String>? name,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (number != null) 'number': number,
      if (name != null) 'name': name,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LinesCompanion copyWith({
    Value<int>? id,
    Value<String>? number,
    Value<String>? name,
    Value<bool>? active,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return LinesCompanion(
      id: id ?? this.id,
      number: number ?? this.number,
      name: name ?? this.name,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (number.present) {
      map['number'] = Variable<String>(number.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LinesCompanion(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('name: $name, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BranchesTable extends Branches
    with TableInfo<$BranchesTable, BranchEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BranchesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _lineIdMeta = const VerificationMeta('lineId');
  @override
  late final GeneratedColumn<int> lineId = GeneratedColumn<int>(
    'line_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lines (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lineId,
    name,
    description,
    active,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'branches';
  @override
  VerificationContext validateIntegrity(
    Insertable<BranchEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('line_id')) {
      context.handle(
        _lineIdMeta,
        lineId.isAcceptableOrUnknown(data['line_id']!, _lineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lineIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BranchEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BranchEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BranchesTable createAlias(String alias) {
    return $BranchesTable(attachedDatabase, alias);
  }
}

class BranchEntry extends DataClass implements Insertable<BranchEntry> {
  final int id;
  final int lineId;
  final String name;
  final String? description;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BranchEntry({
    required this.id,
    required this.lineId,
    required this.name,
    this.description,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['line_id'] = Variable<int>(lineId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BranchesCompanion toCompanion(bool nullToAbsent) {
    return BranchesCompanion(
      id: Value(id),
      lineId: Value(lineId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      active: Value(active),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BranchEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BranchEntry(
      id: serializer.fromJson<int>(json['id']),
      lineId: serializer.fromJson<int>(json['lineId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lineId': serializer.toJson<int>(lineId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BranchEntry copyWith({
    int? id,
    int? lineId,
    String? name,
    Value<String?> description = const Value.absent(),
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BranchEntry(
    id: id ?? this.id,
    lineId: lineId ?? this.lineId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BranchEntry copyWithCompanion(BranchesCompanion data) {
    return BranchEntry(
      id: data.id.present ? data.id.value : this.id,
      lineId: data.lineId.present ? data.lineId.value : this.lineId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BranchEntry(')
          ..write('id: $id, ')
          ..write('lineId: $lineId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, lineId, name, description, active, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BranchEntry &&
          other.id == this.id &&
          other.lineId == this.lineId &&
          other.name == this.name &&
          other.description == this.description &&
          other.active == this.active &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BranchesCompanion extends UpdateCompanion<BranchEntry> {
  final Value<int> id;
  final Value<int> lineId;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BranchesCompanion({
    this.id = const Value.absent(),
    this.lineId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BranchesCompanion.insert({
    this.id = const Value.absent(),
    required int lineId,
    required String name,
    this.description = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : lineId = Value(lineId),
       name = Value(name);
  static Insertable<BranchEntry> custom({
    Expression<int>? id,
    Expression<int>? lineId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lineId != null) 'line_id': lineId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BranchesCompanion copyWith({
    Value<int>? id,
    Value<int>? lineId,
    Value<String>? name,
    Value<String?>? description,
    Value<bool>? active,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BranchesCompanion(
      id: id ?? this.id,
      lineId: lineId ?? this.lineId,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lineId.present) {
      map['line_id'] = Variable<int>(lineId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BranchesCompanion(')
          ..write('id: $id, ')
          ..write('lineId: $lineId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TripsTable extends Trips with TableInfo<$TripsTable, TripEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineIdMeta = const VerificationMeta('lineId');
  @override
  late final GeneratedColumn<int> lineId = GeneratedColumn<int>(
    'line_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lines (id)',
    ),
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES branches (id)',
    ),
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _internalNumberMeta = const VerificationMeta(
    'internalNumber',
  );
  @override
  late final GeneratedColumn<String> internalNumber = GeneratedColumn<String>(
    'internal_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _domainMeta = const VerificationMeta('domain');
  @override
  late final GeneratedColumn<String> domain = GeneratedColumn<String>(
    'domain',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _driverNameMeta = const VerificationMeta(
    'driverName',
  );
  @override
  late final GeneratedColumn<String> driverName = GeneratedColumn<String>(
    'driver_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVE'),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _movingTimeMsMeta = const VerificationMeta(
    'movingTimeMs',
  );
  @override
  late final GeneratedColumn<int> movingTimeMs = GeneratedColumn<int>(
    'moving_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stoppedTimeMsMeta = const VerificationMeta(
    'stoppedTimeMs',
  );
  @override
  late final GeneratedColumn<int> stoppedTimeMs = GeneratedColumn<int>(
    'stopped_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _averageSpeedKmhMeta = const VerificationMeta(
    'averageSpeedKmh',
  );
  @override
  late final GeneratedColumn<double> averageSpeedKmh = GeneratedColumn<double>(
    'average_speed_kmh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _maxSpeedKmhMeta = const VerificationMeta(
    'maxSpeedKmh',
  );
  @override
  late final GeneratedColumn<double> maxSpeedKmh = GeneratedColumn<double>(
    'max_speed_kmh',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _pointCountMeta = const VerificationMeta(
    'pointCount',
  );
  @override
  late final GeneratedColumn<int> pointCount = GeneratedColumn<int>(
    'point_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stopCountMeta = const VerificationMeta(
    'stopCount',
  );
  @override
  late final GeneratedColumn<int> stopCount = GeneratedColumn<int>(
    'stop_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _incidentCountMeta = const VerificationMeta(
    'incidentCount',
  );
  @override
  late final GeneratedColumn<int> incidentCount = GeneratedColumn<int>(
    'incident_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lineId,
    branchId,
    direction,
    internalNumber,
    domain,
    driverName,
    notes,
    status,
    startedAt,
    endedAt,
    durationMs,
    distanceMeters,
    movingTimeMs,
    stoppedTimeMs,
    averageSpeedKmh,
    maxSpeedKmh,
    pointCount,
    stopCount,
    incidentCount,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<TripEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('line_id')) {
      context.handle(
        _lineIdMeta,
        lineId.isAcceptableOrUnknown(data['line_id']!, _lineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lineIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('internal_number')) {
      context.handle(
        _internalNumberMeta,
        internalNumber.isAcceptableOrUnknown(
          data['internal_number']!,
          _internalNumberMeta,
        ),
      );
    }
    if (data.containsKey('domain')) {
      context.handle(
        _domainMeta,
        domain.isAcceptableOrUnknown(data['domain']!, _domainMeta),
      );
    }
    if (data.containsKey('driver_name')) {
      context.handle(
        _driverNameMeta,
        driverName.isAcceptableOrUnknown(data['driver_name']!, _driverNameMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('moving_time_ms')) {
      context.handle(
        _movingTimeMsMeta,
        movingTimeMs.isAcceptableOrUnknown(
          data['moving_time_ms']!,
          _movingTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('stopped_time_ms')) {
      context.handle(
        _stoppedTimeMsMeta,
        stoppedTimeMs.isAcceptableOrUnknown(
          data['stopped_time_ms']!,
          _stoppedTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('average_speed_kmh')) {
      context.handle(
        _averageSpeedKmhMeta,
        averageSpeedKmh.isAcceptableOrUnknown(
          data['average_speed_kmh']!,
          _averageSpeedKmhMeta,
        ),
      );
    }
    if (data.containsKey('max_speed_kmh')) {
      context.handle(
        _maxSpeedKmhMeta,
        maxSpeedKmh.isAcceptableOrUnknown(
          data['max_speed_kmh']!,
          _maxSpeedKmhMeta,
        ),
      );
    }
    if (data.containsKey('point_count')) {
      context.handle(
        _pointCountMeta,
        pointCount.isAcceptableOrUnknown(data['point_count']!, _pointCountMeta),
      );
    }
    if (data.containsKey('stop_count')) {
      context.handle(
        _stopCountMeta,
        stopCount.isAcceptableOrUnknown(data['stop_count']!, _stopCountMeta),
      );
    }
    if (data.containsKey('incident_count')) {
      context.handle(
        _incidentCountMeta,
        incidentCount.isAcceptableOrUnknown(
          data['incident_count']!,
          _incidentCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TripEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}branch_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      internalNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}internal_number'],
      ),
      domain: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain'],
      ),
      driverName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}driver_name'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      )!,
      movingTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_time_ms'],
      )!,
      stoppedTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stopped_time_ms'],
      )!,
      averageSpeedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_speed_kmh'],
      )!,
      maxSpeedKmh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_speed_kmh'],
      )!,
      pointCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}point_count'],
      )!,
      stopCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stop_count'],
      )!,
      incidentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}incident_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class TripEntry extends DataClass implements Insertable<TripEntry> {
  final String id;
  final int lineId;
  final int branchId;
  final String direction;
  final String? internalNumber;
  final String? domain;
  final String? driverName;
  final String? notes;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationMs;
  final double distanceMeters;
  final int movingTimeMs;
  final int stoppedTimeMs;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final int pointCount;
  final int stopCount;
  final int incidentCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TripEntry({
    required this.id,
    required this.lineId,
    required this.branchId,
    required this.direction,
    this.internalNumber,
    this.domain,
    this.driverName,
    this.notes,
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.durationMs,
    required this.distanceMeters,
    required this.movingTimeMs,
    required this.stoppedTimeMs,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.pointCount,
    required this.stopCount,
    required this.incidentCount,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['line_id'] = Variable<int>(lineId);
    map['branch_id'] = Variable<int>(branchId);
    map['direction'] = Variable<String>(direction);
    if (!nullToAbsent || internalNumber != null) {
      map['internal_number'] = Variable<String>(internalNumber);
    }
    if (!nullToAbsent || domain != null) {
      map['domain'] = Variable<String>(domain);
    }
    if (!nullToAbsent || driverName != null) {
      map['driver_name'] = Variable<String>(driverName);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['status'] = Variable<String>(status);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['distance_meters'] = Variable<double>(distanceMeters);
    map['moving_time_ms'] = Variable<int>(movingTimeMs);
    map['stopped_time_ms'] = Variable<int>(stoppedTimeMs);
    map['average_speed_kmh'] = Variable<double>(averageSpeedKmh);
    map['max_speed_kmh'] = Variable<double>(maxSpeedKmh);
    map['point_count'] = Variable<int>(pointCount);
    map['stop_count'] = Variable<int>(stopCount);
    map['incident_count'] = Variable<int>(incidentCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      id: Value(id),
      lineId: Value(lineId),
      branchId: Value(branchId),
      direction: Value(direction),
      internalNumber: internalNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(internalNumber),
      domain: domain == null && nullToAbsent
          ? const Value.absent()
          : Value(domain),
      driverName: driverName == null && nullToAbsent
          ? const Value.absent()
          : Value(driverName),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      durationMs: Value(durationMs),
      distanceMeters: Value(distanceMeters),
      movingTimeMs: Value(movingTimeMs),
      stoppedTimeMs: Value(stoppedTimeMs),
      averageSpeedKmh: Value(averageSpeedKmh),
      maxSpeedKmh: Value(maxSpeedKmh),
      pointCount: Value(pointCount),
      stopCount: Value(stopCount),
      incidentCount: Value(incidentCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TripEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripEntry(
      id: serializer.fromJson<String>(json['id']),
      lineId: serializer.fromJson<int>(json['lineId']),
      branchId: serializer.fromJson<int>(json['branchId']),
      direction: serializer.fromJson<String>(json['direction']),
      internalNumber: serializer.fromJson<String?>(json['internalNumber']),
      domain: serializer.fromJson<String?>(json['domain']),
      driverName: serializer.fromJson<String?>(json['driverName']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<String>(json['status']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      movingTimeMs: serializer.fromJson<int>(json['movingTimeMs']),
      stoppedTimeMs: serializer.fromJson<int>(json['stoppedTimeMs']),
      averageSpeedKmh: serializer.fromJson<double>(json['averageSpeedKmh']),
      maxSpeedKmh: serializer.fromJson<double>(json['maxSpeedKmh']),
      pointCount: serializer.fromJson<int>(json['pointCount']),
      stopCount: serializer.fromJson<int>(json['stopCount']),
      incidentCount: serializer.fromJson<int>(json['incidentCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lineId': serializer.toJson<int>(lineId),
      'branchId': serializer.toJson<int>(branchId),
      'direction': serializer.toJson<String>(direction),
      'internalNumber': serializer.toJson<String?>(internalNumber),
      'domain': serializer.toJson<String?>(domain),
      'driverName': serializer.toJson<String?>(driverName),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(status),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'durationMs': serializer.toJson<int>(durationMs),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'movingTimeMs': serializer.toJson<int>(movingTimeMs),
      'stoppedTimeMs': serializer.toJson<int>(stoppedTimeMs),
      'averageSpeedKmh': serializer.toJson<double>(averageSpeedKmh),
      'maxSpeedKmh': serializer.toJson<double>(maxSpeedKmh),
      'pointCount': serializer.toJson<int>(pointCount),
      'stopCount': serializer.toJson<int>(stopCount),
      'incidentCount': serializer.toJson<int>(incidentCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TripEntry copyWith({
    String? id,
    int? lineId,
    int? branchId,
    String? direction,
    Value<String?> internalNumber = const Value.absent(),
    Value<String?> domain = const Value.absent(),
    Value<String?> driverName = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? status,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? durationMs,
    double? distanceMeters,
    int? movingTimeMs,
    int? stoppedTimeMs,
    double? averageSpeedKmh,
    double? maxSpeedKmh,
    int? pointCount,
    int? stopCount,
    int? incidentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TripEntry(
    id: id ?? this.id,
    lineId: lineId ?? this.lineId,
    branchId: branchId ?? this.branchId,
    direction: direction ?? this.direction,
    internalNumber: internalNumber.present
        ? internalNumber.value
        : this.internalNumber,
    domain: domain.present ? domain.value : this.domain,
    driverName: driverName.present ? driverName.value : this.driverName,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    durationMs: durationMs ?? this.durationMs,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    movingTimeMs: movingTimeMs ?? this.movingTimeMs,
    stoppedTimeMs: stoppedTimeMs ?? this.stoppedTimeMs,
    averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
    maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
    pointCount: pointCount ?? this.pointCount,
    stopCount: stopCount ?? this.stopCount,
    incidentCount: incidentCount ?? this.incidentCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TripEntry copyWithCompanion(TripsCompanion data) {
    return TripEntry(
      id: data.id.present ? data.id.value : this.id,
      lineId: data.lineId.present ? data.lineId.value : this.lineId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      direction: data.direction.present ? data.direction.value : this.direction,
      internalNumber: data.internalNumber.present
          ? data.internalNumber.value
          : this.internalNumber,
      domain: data.domain.present ? data.domain.value : this.domain,
      driverName: data.driverName.present
          ? data.driverName.value
          : this.driverName,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      movingTimeMs: data.movingTimeMs.present
          ? data.movingTimeMs.value
          : this.movingTimeMs,
      stoppedTimeMs: data.stoppedTimeMs.present
          ? data.stoppedTimeMs.value
          : this.stoppedTimeMs,
      averageSpeedKmh: data.averageSpeedKmh.present
          ? data.averageSpeedKmh.value
          : this.averageSpeedKmh,
      maxSpeedKmh: data.maxSpeedKmh.present
          ? data.maxSpeedKmh.value
          : this.maxSpeedKmh,
      pointCount: data.pointCount.present
          ? data.pointCount.value
          : this.pointCount,
      stopCount: data.stopCount.present ? data.stopCount.value : this.stopCount,
      incidentCount: data.incidentCount.present
          ? data.incidentCount.value
          : this.incidentCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripEntry(')
          ..write('id: $id, ')
          ..write('lineId: $lineId, ')
          ..write('branchId: $branchId, ')
          ..write('direction: $direction, ')
          ..write('internalNumber: $internalNumber, ')
          ..write('domain: $domain, ')
          ..write('driverName: $driverName, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('movingTimeMs: $movingTimeMs, ')
          ..write('stoppedTimeMs: $stoppedTimeMs, ')
          ..write('averageSpeedKmh: $averageSpeedKmh, ')
          ..write('maxSpeedKmh: $maxSpeedKmh, ')
          ..write('pointCount: $pointCount, ')
          ..write('stopCount: $stopCount, ')
          ..write('incidentCount: $incidentCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    lineId,
    branchId,
    direction,
    internalNumber,
    domain,
    driverName,
    notes,
    status,
    startedAt,
    endedAt,
    durationMs,
    distanceMeters,
    movingTimeMs,
    stoppedTimeMs,
    averageSpeedKmh,
    maxSpeedKmh,
    pointCount,
    stopCount,
    incidentCount,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripEntry &&
          other.id == this.id &&
          other.lineId == this.lineId &&
          other.branchId == this.branchId &&
          other.direction == this.direction &&
          other.internalNumber == this.internalNumber &&
          other.domain == this.domain &&
          other.driverName == this.driverName &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationMs == this.durationMs &&
          other.distanceMeters == this.distanceMeters &&
          other.movingTimeMs == this.movingTimeMs &&
          other.stoppedTimeMs == this.stoppedTimeMs &&
          other.averageSpeedKmh == this.averageSpeedKmh &&
          other.maxSpeedKmh == this.maxSpeedKmh &&
          other.pointCount == this.pointCount &&
          other.stopCount == this.stopCount &&
          other.incidentCount == this.incidentCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TripsCompanion extends UpdateCompanion<TripEntry> {
  final Value<String> id;
  final Value<int> lineId;
  final Value<int> branchId;
  final Value<String> direction;
  final Value<String?> internalNumber;
  final Value<String?> domain;
  final Value<String?> driverName;
  final Value<String?> notes;
  final Value<String> status;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> durationMs;
  final Value<double> distanceMeters;
  final Value<int> movingTimeMs;
  final Value<int> stoppedTimeMs;
  final Value<double> averageSpeedKmh;
  final Value<double> maxSpeedKmh;
  final Value<int> pointCount;
  final Value<int> stopCount;
  final Value<int> incidentCount;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.lineId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.direction = const Value.absent(),
    this.internalNumber = const Value.absent(),
    this.domain = const Value.absent(),
    this.driverName = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.movingTimeMs = const Value.absent(),
    this.stoppedTimeMs = const Value.absent(),
    this.averageSpeedKmh = const Value.absent(),
    this.maxSpeedKmh = const Value.absent(),
    this.pointCount = const Value.absent(),
    this.stopCount = const Value.absent(),
    this.incidentCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TripsCompanion.insert({
    required String id,
    required int lineId,
    required int branchId,
    required String direction,
    this.internalNumber = const Value.absent(),
    this.domain = const Value.absent(),
    this.driverName = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.movingTimeMs = const Value.absent(),
    this.stoppedTimeMs = const Value.absent(),
    this.averageSpeedKmh = const Value.absent(),
    this.maxSpeedKmh = const Value.absent(),
    this.pointCount = const Value.absent(),
    this.stopCount = const Value.absent(),
    this.incidentCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lineId = Value(lineId),
       branchId = Value(branchId),
       direction = Value(direction);
  static Insertable<TripEntry> custom({
    Expression<String>? id,
    Expression<int>? lineId,
    Expression<int>? branchId,
    Expression<String>? direction,
    Expression<String>? internalNumber,
    Expression<String>? domain,
    Expression<String>? driverName,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? durationMs,
    Expression<double>? distanceMeters,
    Expression<int>? movingTimeMs,
    Expression<int>? stoppedTimeMs,
    Expression<double>? averageSpeedKmh,
    Expression<double>? maxSpeedKmh,
    Expression<int>? pointCount,
    Expression<int>? stopCount,
    Expression<int>? incidentCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lineId != null) 'line_id': lineId,
      if (branchId != null) 'branch_id': branchId,
      if (direction != null) 'direction': direction,
      if (internalNumber != null) 'internal_number': internalNumber,
      if (domain != null) 'domain': domain,
      if (driverName != null) 'driver_name': driverName,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (movingTimeMs != null) 'moving_time_ms': movingTimeMs,
      if (stoppedTimeMs != null) 'stopped_time_ms': stoppedTimeMs,
      if (averageSpeedKmh != null) 'average_speed_kmh': averageSpeedKmh,
      if (maxSpeedKmh != null) 'max_speed_kmh': maxSpeedKmh,
      if (pointCount != null) 'point_count': pointCount,
      if (stopCount != null) 'stop_count': stopCount,
      if (incidentCount != null) 'incident_count': incidentCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TripsCompanion copyWith({
    Value<String>? id,
    Value<int>? lineId,
    Value<int>? branchId,
    Value<String>? direction,
    Value<String?>? internalNumber,
    Value<String?>? domain,
    Value<String?>? driverName,
    Value<String?>? notes,
    Value<String>? status,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? durationMs,
    Value<double>? distanceMeters,
    Value<int>? movingTimeMs,
    Value<int>? stoppedTimeMs,
    Value<double>? averageSpeedKmh,
    Value<double>? maxSpeedKmh,
    Value<int>? pointCount,
    Value<int>? stopCount,
    Value<int>? incidentCount,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TripsCompanion(
      id: id ?? this.id,
      lineId: lineId ?? this.lineId,
      branchId: branchId ?? this.branchId,
      direction: direction ?? this.direction,
      internalNumber: internalNumber ?? this.internalNumber,
      domain: domain ?? this.domain,
      driverName: driverName ?? this.driverName,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMs: durationMs ?? this.durationMs,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      movingTimeMs: movingTimeMs ?? this.movingTimeMs,
      stoppedTimeMs: stoppedTimeMs ?? this.stoppedTimeMs,
      averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      pointCount: pointCount ?? this.pointCount,
      stopCount: stopCount ?? this.stopCount,
      incidentCount: incidentCount ?? this.incidentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lineId.present) {
      map['line_id'] = Variable<int>(lineId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (internalNumber.present) {
      map['internal_number'] = Variable<String>(internalNumber.value);
    }
    if (domain.present) {
      map['domain'] = Variable<String>(domain.value);
    }
    if (driverName.present) {
      map['driver_name'] = Variable<String>(driverName.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (movingTimeMs.present) {
      map['moving_time_ms'] = Variable<int>(movingTimeMs.value);
    }
    if (stoppedTimeMs.present) {
      map['stopped_time_ms'] = Variable<int>(stoppedTimeMs.value);
    }
    if (averageSpeedKmh.present) {
      map['average_speed_kmh'] = Variable<double>(averageSpeedKmh.value);
    }
    if (maxSpeedKmh.present) {
      map['max_speed_kmh'] = Variable<double>(maxSpeedKmh.value);
    }
    if (pointCount.present) {
      map['point_count'] = Variable<int>(pointCount.value);
    }
    if (stopCount.present) {
      map['stop_count'] = Variable<int>(stopCount.value);
    }
    if (incidentCount.present) {
      map['incident_count'] = Variable<int>(incidentCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('id: $id, ')
          ..write('lineId: $lineId, ')
          ..write('branchId: $branchId, ')
          ..write('direction: $direction, ')
          ..write('internalNumber: $internalNumber, ')
          ..write('domain: $domain, ')
          ..write('driverName: $driverName, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('movingTimeMs: $movingTimeMs, ')
          ..write('stoppedTimeMs: $stoppedTimeMs, ')
          ..write('averageSpeedKmh: $averageSpeedKmh, ')
          ..write('maxSpeedKmh: $maxSpeedKmh, ')
          ..write('pointCount: $pointCount, ')
          ..write('stopCount: $stopCount, ')
          ..write('incidentCount: $incidentCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrackPointsTable extends TrackPoints
    with TableInfo<$TrackPointsTable, TrackPointEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackPointsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _elapsedRealtimeNanosMeta =
      const VerificationMeta('elapsedRealtimeNanos');
  @override
  late final GeneratedColumn<int> elapsedRealtimeNanos = GeneratedColumn<int>(
    'elapsed_realtime_nanos',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altitudeMeta = const VerificationMeta(
    'altitude',
  );
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
    'altitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedMpsMeta = const VerificationMeta(
    'speedMps',
  );
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
    'speed_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bearingDegreesMeta = const VerificationMeta(
    'bearingDegrees',
  );
  @override
  late final GeneratedColumn<double> bearingDegrees = GeneratedColumn<double>(
    'bearing_degrees',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
    'quality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('GOOD'),
  );
  static const VerificationMeta _isAcceptedMeta = const VerificationMeta(
    'isAccepted',
  );
  @override
  late final GeneratedColumn<bool> isAccepted = GeneratedColumn<bool>(
    'is_accepted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_accepted" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    timestamp,
    elapsedRealtimeNanos,
    latitude,
    longitude,
    altitude,
    accuracy,
    speedMps,
    bearingDegrees,
    provider,
    quality,
    isAccepted,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<TrackPointEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('elapsed_realtime_nanos')) {
      context.handle(
        _elapsedRealtimeNanosMeta,
        elapsedRealtimeNanos.isAcceptableOrUnknown(
          data['elapsed_realtime_nanos']!,
          _elapsedRealtimeNanosMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('altitude')) {
      context.handle(
        _altitudeMeta,
        altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta),
      );
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    }
    if (data.containsKey('speed_mps')) {
      context.handle(
        _speedMpsMeta,
        speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta),
      );
    }
    if (data.containsKey('bearing_degrees')) {
      context.handle(
        _bearingDegreesMeta,
        bearingDegrees.isAcceptableOrUnknown(
          data['bearing_degrees']!,
          _bearingDegreesMeta,
        ),
      );
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    }
    if (data.containsKey('is_accepted')) {
      context.handle(
        _isAcceptedMeta,
        isAccepted.isAcceptableOrUnknown(data['is_accepted']!, _isAcceptedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackPointEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackPointEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      elapsedRealtimeNanos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_realtime_nanos'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      altitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude'],
      ),
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      ),
      speedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_mps'],
      ),
      bearingDegrees: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bearing_degrees'],
      ),
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      ),
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality'],
      )!,
      isAccepted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_accepted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TrackPointsTable createAlias(String alias) {
    return $TrackPointsTable(attachedDatabase, alias);
  }
}

class TrackPointEntry extends DataClass implements Insertable<TrackPointEntry> {
  final int id;
  final String tripId;
  final DateTime timestamp;
  final int? elapsedRealtimeNanos;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speedMps;
  final double? bearingDegrees;
  final String? provider;
  final String quality;
  final bool isAccepted;
  final DateTime createdAt;
  const TrackPointEntry({
    required this.id,
    required this.tripId,
    required this.timestamp,
    this.elapsedRealtimeNanos,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speedMps,
    this.bearingDegrees,
    this.provider,
    required this.quality,
    required this.isAccepted,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || elapsedRealtimeNanos != null) {
      map['elapsed_realtime_nanos'] = Variable<int>(elapsedRealtimeNanos);
    }
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || altitude != null) {
      map['altitude'] = Variable<double>(altitude);
    }
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    if (!nullToAbsent || speedMps != null) {
      map['speed_mps'] = Variable<double>(speedMps);
    }
    if (!nullToAbsent || bearingDegrees != null) {
      map['bearing_degrees'] = Variable<double>(bearingDegrees);
    }
    if (!nullToAbsent || provider != null) {
      map['provider'] = Variable<String>(provider);
    }
    map['quality'] = Variable<String>(quality);
    map['is_accepted'] = Variable<bool>(isAccepted);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TrackPointsCompanion toCompanion(bool nullToAbsent) {
    return TrackPointsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      timestamp: Value(timestamp),
      elapsedRealtimeNanos: elapsedRealtimeNanos == null && nullToAbsent
          ? const Value.absent()
          : Value(elapsedRealtimeNanos),
      latitude: Value(latitude),
      longitude: Value(longitude),
      altitude: altitude == null && nullToAbsent
          ? const Value.absent()
          : Value(altitude),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
      speedMps: speedMps == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMps),
      bearingDegrees: bearingDegrees == null && nullToAbsent
          ? const Value.absent()
          : Value(bearingDegrees),
      provider: provider == null && nullToAbsent
          ? const Value.absent()
          : Value(provider),
      quality: Value(quality),
      isAccepted: Value(isAccepted),
      createdAt: Value(createdAt),
    );
  }

  factory TrackPointEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackPointEntry(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      elapsedRealtimeNanos: serializer.fromJson<int?>(
        json['elapsedRealtimeNanos'],
      ),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      altitude: serializer.fromJson<double?>(json['altitude']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      speedMps: serializer.fromJson<double?>(json['speedMps']),
      bearingDegrees: serializer.fromJson<double?>(json['bearingDegrees']),
      provider: serializer.fromJson<String?>(json['provider']),
      quality: serializer.fromJson<String>(json['quality']),
      isAccepted: serializer.fromJson<bool>(json['isAccepted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<String>(tripId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'elapsedRealtimeNanos': serializer.toJson<int?>(elapsedRealtimeNanos),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'altitude': serializer.toJson<double?>(altitude),
      'accuracy': serializer.toJson<double?>(accuracy),
      'speedMps': serializer.toJson<double?>(speedMps),
      'bearingDegrees': serializer.toJson<double?>(bearingDegrees),
      'provider': serializer.toJson<String?>(provider),
      'quality': serializer.toJson<String>(quality),
      'isAccepted': serializer.toJson<bool>(isAccepted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TrackPointEntry copyWith({
    int? id,
    String? tripId,
    DateTime? timestamp,
    Value<int?> elapsedRealtimeNanos = const Value.absent(),
    double? latitude,
    double? longitude,
    Value<double?> altitude = const Value.absent(),
    Value<double?> accuracy = const Value.absent(),
    Value<double?> speedMps = const Value.absent(),
    Value<double?> bearingDegrees = const Value.absent(),
    Value<String?> provider = const Value.absent(),
    String? quality,
    bool? isAccepted,
    DateTime? createdAt,
  }) => TrackPointEntry(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    timestamp: timestamp ?? this.timestamp,
    elapsedRealtimeNanos: elapsedRealtimeNanos.present
        ? elapsedRealtimeNanos.value
        : this.elapsedRealtimeNanos,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    altitude: altitude.present ? altitude.value : this.altitude,
    accuracy: accuracy.present ? accuracy.value : this.accuracy,
    speedMps: speedMps.present ? speedMps.value : this.speedMps,
    bearingDegrees: bearingDegrees.present
        ? bearingDegrees.value
        : this.bearingDegrees,
    provider: provider.present ? provider.value : this.provider,
    quality: quality ?? this.quality,
    isAccepted: isAccepted ?? this.isAccepted,
    createdAt: createdAt ?? this.createdAt,
  );
  TrackPointEntry copyWithCompanion(TrackPointsCompanion data) {
    return TrackPointEntry(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      elapsedRealtimeNanos: data.elapsedRealtimeNanos.present
          ? data.elapsedRealtimeNanos.value
          : this.elapsedRealtimeNanos,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
      bearingDegrees: data.bearingDegrees.present
          ? data.bearingDegrees.value
          : this.bearingDegrees,
      provider: data.provider.present ? data.provider.value : this.provider,
      quality: data.quality.present ? data.quality.value : this.quality,
      isAccepted: data.isAccepted.present
          ? data.isAccepted.value
          : this.isAccepted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackPointEntry(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('timestamp: $timestamp, ')
          ..write('elapsedRealtimeNanos: $elapsedRealtimeNanos, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('speedMps: $speedMps, ')
          ..write('bearingDegrees: $bearingDegrees, ')
          ..write('provider: $provider, ')
          ..write('quality: $quality, ')
          ..write('isAccepted: $isAccepted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    timestamp,
    elapsedRealtimeNanos,
    latitude,
    longitude,
    altitude,
    accuracy,
    speedMps,
    bearingDegrees,
    provider,
    quality,
    isAccepted,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackPointEntry &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.timestamp == this.timestamp &&
          other.elapsedRealtimeNanos == this.elapsedRealtimeNanos &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.altitude == this.altitude &&
          other.accuracy == this.accuracy &&
          other.speedMps == this.speedMps &&
          other.bearingDegrees == this.bearingDegrees &&
          other.provider == this.provider &&
          other.quality == this.quality &&
          other.isAccepted == this.isAccepted &&
          other.createdAt == this.createdAt);
}

class TrackPointsCompanion extends UpdateCompanion<TrackPointEntry> {
  final Value<int> id;
  final Value<String> tripId;
  final Value<DateTime> timestamp;
  final Value<int?> elapsedRealtimeNanos;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> altitude;
  final Value<double?> accuracy;
  final Value<double?> speedMps;
  final Value<double?> bearingDegrees;
  final Value<String?> provider;
  final Value<String> quality;
  final Value<bool> isAccepted;
  final Value<DateTime> createdAt;
  const TrackPointsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.elapsedRealtimeNanos = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.altitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.bearingDegrees = const Value.absent(),
    this.provider = const Value.absent(),
    this.quality = const Value.absent(),
    this.isAccepted = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TrackPointsCompanion.insert({
    this.id = const Value.absent(),
    required String tripId,
    this.timestamp = const Value.absent(),
    this.elapsedRealtimeNanos = const Value.absent(),
    required double latitude,
    required double longitude,
    this.altitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.bearingDegrees = const Value.absent(),
    this.provider = const Value.absent(),
    this.quality = const Value.absent(),
    this.isAccepted = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : tripId = Value(tripId),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<TrackPointEntry> custom({
    Expression<int>? id,
    Expression<String>? tripId,
    Expression<DateTime>? timestamp,
    Expression<int>? elapsedRealtimeNanos,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? altitude,
    Expression<double>? accuracy,
    Expression<double>? speedMps,
    Expression<double>? bearingDegrees,
    Expression<String>? provider,
    Expression<String>? quality,
    Expression<bool>? isAccepted,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (timestamp != null) 'timestamp': timestamp,
      if (elapsedRealtimeNanos != null)
        'elapsed_realtime_nanos': elapsedRealtimeNanos,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (speedMps != null) 'speed_mps': speedMps,
      if (bearingDegrees != null) 'bearing_degrees': bearingDegrees,
      if (provider != null) 'provider': provider,
      if (quality != null) 'quality': quality,
      if (isAccepted != null) 'is_accepted': isAccepted,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TrackPointsCompanion copyWith({
    Value<int>? id,
    Value<String>? tripId,
    Value<DateTime>? timestamp,
    Value<int?>? elapsedRealtimeNanos,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double?>? altitude,
    Value<double?>? accuracy,
    Value<double?>? speedMps,
    Value<double?>? bearingDegrees,
    Value<String?>? provider,
    Value<String>? quality,
    Value<bool>? isAccepted,
    Value<DateTime>? createdAt,
  }) {
    return TrackPointsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      timestamp: timestamp ?? this.timestamp,
      elapsedRealtimeNanos: elapsedRealtimeNanos ?? this.elapsedRealtimeNanos,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      speedMps: speedMps ?? this.speedMps,
      bearingDegrees: bearingDegrees ?? this.bearingDegrees,
      provider: provider ?? this.provider,
      quality: quality ?? this.quality,
      isAccepted: isAccepted ?? this.isAccepted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (elapsedRealtimeNanos.present) {
      map['elapsed_realtime_nanos'] = Variable<int>(elapsedRealtimeNanos.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    if (bearingDegrees.present) {
      map['bearing_degrees'] = Variable<double>(bearingDegrees.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (isAccepted.present) {
      map['is_accepted'] = Variable<bool>(isAccepted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackPointsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('timestamp: $timestamp, ')
          ..write('elapsedRealtimeNanos: $elapsedRealtimeNanos, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('speedMps: $speedMps, ')
          ..write('bearingDegrees: $bearingDegrees, ')
          ..write('provider: $provider, ')
          ..write('quality: $quality, ')
          ..write('isAccepted: $isAccepted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $StopsTable extends Stops with TableInfo<$StopsTable, StopEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StopsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _markedAtMeta = const VerificationMeta(
    'markedAt',
  );
  @override
  late final GeneratedColumn<DateTime> markedAt = GeneratedColumn<DateTime>(
    'marked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _arrivalAtMeta = const VerificationMeta(
    'arrivalAt',
  );
  @override
  late final GeneratedColumn<DateTime> arrivalAt = GeneratedColumn<DateTime>(
    'arrival_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _departureAtMeta = const VerificationMeta(
    'departureAt',
  );
  @override
  late final GeneratedColumn<DateTime> departureAt = GeneratedColumn<DateTime>(
    'departure_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dwellTimeMsMeta = const VerificationMeta(
    'dwellTimeMs',
  );
  @override
  late final GeneratedColumn<int> dwellTimeMs = GeneratedColumn<int>(
    'dwell_time_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('MANUAL'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    sequence,
    latitude,
    longitude,
    accuracy,
    markedAt,
    arrivalAt,
    departureAt,
    dwellTimeMs,
    name,
    code,
    status,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stops';
  @override
  VerificationContext validateIntegrity(
    Insertable<StopEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    }
    if (data.containsKey('marked_at')) {
      context.handle(
        _markedAtMeta,
        markedAt.isAcceptableOrUnknown(data['marked_at']!, _markedAtMeta),
      );
    }
    if (data.containsKey('arrival_at')) {
      context.handle(
        _arrivalAtMeta,
        arrivalAt.isAcceptableOrUnknown(data['arrival_at']!, _arrivalAtMeta),
      );
    }
    if (data.containsKey('departure_at')) {
      context.handle(
        _departureAtMeta,
        departureAt.isAcceptableOrUnknown(
          data['departure_at']!,
          _departureAtMeta,
        ),
      );
    }
    if (data.containsKey('dwell_time_ms')) {
      context.handle(
        _dwellTimeMsMeta,
        dwellTimeMs.isAcceptableOrUnknown(
          data['dwell_time_ms']!,
          _dwellTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StopEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StopEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      ),
      markedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}marked_at'],
      )!,
      arrivalAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}arrival_at'],
      ),
      departureAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}departure_at'],
      ),
      dwellTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dwell_time_ms'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StopsTable createAlias(String alias) {
    return $StopsTable(attachedDatabase, alias);
  }
}

class StopEntry extends DataClass implements Insertable<StopEntry> {
  final int id;
  final String tripId;
  final int sequence;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime markedAt;
  final DateTime? arrivalAt;
  final DateTime? departureAt;
  final int? dwellTimeMs;
  final String? name;
  final String? code;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StopEntry({
    required this.id,
    required this.tripId,
    required this.sequence,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.markedAt,
    this.arrivalAt,
    this.departureAt,
    this.dwellTimeMs,
    this.name,
    this.code,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['sequence'] = Variable<int>(sequence);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    map['marked_at'] = Variable<DateTime>(markedAt);
    if (!nullToAbsent || arrivalAt != null) {
      map['arrival_at'] = Variable<DateTime>(arrivalAt);
    }
    if (!nullToAbsent || departureAt != null) {
      map['departure_at'] = Variable<DateTime>(departureAt);
    }
    if (!nullToAbsent || dwellTimeMs != null) {
      map['dwell_time_ms'] = Variable<int>(dwellTimeMs);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || code != null) {
      map['code'] = Variable<String>(code);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StopsCompanion toCompanion(bool nullToAbsent) {
    return StopsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      sequence: Value(sequence),
      latitude: Value(latitude),
      longitude: Value(longitude),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
      markedAt: Value(markedAt),
      arrivalAt: arrivalAt == null && nullToAbsent
          ? const Value.absent()
          : Value(arrivalAt),
      departureAt: departureAt == null && nullToAbsent
          ? const Value.absent()
          : Value(departureAt),
      dwellTimeMs: dwellTimeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(dwellTimeMs),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      code: code == null && nullToAbsent ? const Value.absent() : Value(code),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StopEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StopEntry(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      markedAt: serializer.fromJson<DateTime>(json['markedAt']),
      arrivalAt: serializer.fromJson<DateTime?>(json['arrivalAt']),
      departureAt: serializer.fromJson<DateTime?>(json['departureAt']),
      dwellTimeMs: serializer.fromJson<int?>(json['dwellTimeMs']),
      name: serializer.fromJson<String?>(json['name']),
      code: serializer.fromJson<String?>(json['code']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<String>(tripId),
      'sequence': serializer.toJson<int>(sequence),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracy': serializer.toJson<double?>(accuracy),
      'markedAt': serializer.toJson<DateTime>(markedAt),
      'arrivalAt': serializer.toJson<DateTime?>(arrivalAt),
      'departureAt': serializer.toJson<DateTime?>(departureAt),
      'dwellTimeMs': serializer.toJson<int?>(dwellTimeMs),
      'name': serializer.toJson<String?>(name),
      'code': serializer.toJson<String?>(code),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StopEntry copyWith({
    int? id,
    String? tripId,
    int? sequence,
    double? latitude,
    double? longitude,
    Value<double?> accuracy = const Value.absent(),
    DateTime? markedAt,
    Value<DateTime?> arrivalAt = const Value.absent(),
    Value<DateTime?> departureAt = const Value.absent(),
    Value<int?> dwellTimeMs = const Value.absent(),
    Value<String?> name = const Value.absent(),
    Value<String?> code = const Value.absent(),
    String? status,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StopEntry(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    sequence: sequence ?? this.sequence,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    accuracy: accuracy.present ? accuracy.value : this.accuracy,
    markedAt: markedAt ?? this.markedAt,
    arrivalAt: arrivalAt.present ? arrivalAt.value : this.arrivalAt,
    departureAt: departureAt.present ? departureAt.value : this.departureAt,
    dwellTimeMs: dwellTimeMs.present ? dwellTimeMs.value : this.dwellTimeMs,
    name: name.present ? name.value : this.name,
    code: code.present ? code.value : this.code,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StopEntry copyWithCompanion(StopsCompanion data) {
    return StopEntry(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      markedAt: data.markedAt.present ? data.markedAt.value : this.markedAt,
      arrivalAt: data.arrivalAt.present ? data.arrivalAt.value : this.arrivalAt,
      departureAt: data.departureAt.present
          ? data.departureAt.value
          : this.departureAt,
      dwellTimeMs: data.dwellTimeMs.present
          ? data.dwellTimeMs.value
          : this.dwellTimeMs,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StopEntry(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('sequence: $sequence, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('markedAt: $markedAt, ')
          ..write('arrivalAt: $arrivalAt, ')
          ..write('departureAt: $departureAt, ')
          ..write('dwellTimeMs: $dwellTimeMs, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    sequence,
    latitude,
    longitude,
    accuracy,
    markedAt,
    arrivalAt,
    departureAt,
    dwellTimeMs,
    name,
    code,
    status,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StopEntry &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.sequence == this.sequence &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracy == this.accuracy &&
          other.markedAt == this.markedAt &&
          other.arrivalAt == this.arrivalAt &&
          other.departureAt == this.departureAt &&
          other.dwellTimeMs == this.dwellTimeMs &&
          other.name == this.name &&
          other.code == this.code &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StopsCompanion extends UpdateCompanion<StopEntry> {
  final Value<int> id;
  final Value<String> tripId;
  final Value<int> sequence;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> accuracy;
  final Value<DateTime> markedAt;
  final Value<DateTime?> arrivalAt;
  final Value<DateTime?> departureAt;
  final Value<int?> dwellTimeMs;
  final Value<String?> name;
  final Value<String?> code;
  final Value<String> status;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const StopsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.markedAt = const Value.absent(),
    this.arrivalAt = const Value.absent(),
    this.departureAt = const Value.absent(),
    this.dwellTimeMs = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  StopsCompanion.insert({
    this.id = const Value.absent(),
    required String tripId,
    this.sequence = const Value.absent(),
    required double latitude,
    required double longitude,
    this.accuracy = const Value.absent(),
    this.markedAt = const Value.absent(),
    this.arrivalAt = const Value.absent(),
    this.departureAt = const Value.absent(),
    this.dwellTimeMs = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : tripId = Value(tripId),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<StopEntry> custom({
    Expression<int>? id,
    Expression<String>? tripId,
    Expression<int>? sequence,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracy,
    Expression<DateTime>? markedAt,
    Expression<DateTime>? arrivalAt,
    Expression<DateTime>? departureAt,
    Expression<int>? dwellTimeMs,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (sequence != null) 'sequence': sequence,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (markedAt != null) 'marked_at': markedAt,
      if (arrivalAt != null) 'arrival_at': arrivalAt,
      if (departureAt != null) 'departure_at': departureAt,
      if (dwellTimeMs != null) 'dwell_time_ms': dwellTimeMs,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  StopsCompanion copyWith({
    Value<int>? id,
    Value<String>? tripId,
    Value<int>? sequence,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double?>? accuracy,
    Value<DateTime>? markedAt,
    Value<DateTime?>? arrivalAt,
    Value<DateTime?>? departureAt,
    Value<int?>? dwellTimeMs,
    Value<String?>? name,
    Value<String?>? code,
    Value<String>? status,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return StopsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      sequence: sequence ?? this.sequence,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      markedAt: markedAt ?? this.markedAt,
      arrivalAt: arrivalAt ?? this.arrivalAt,
      departureAt: departureAt ?? this.departureAt,
      dwellTimeMs: dwellTimeMs ?? this.dwellTimeMs,
      name: name ?? this.name,
      code: code ?? this.code,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (markedAt.present) {
      map['marked_at'] = Variable<DateTime>(markedAt.value);
    }
    if (arrivalAt.present) {
      map['arrival_at'] = Variable<DateTime>(arrivalAt.value);
    }
    if (departureAt.present) {
      map['departure_at'] = Variable<DateTime>(departureAt.value);
    }
    if (dwellTimeMs.present) {
      map['dwell_time_ms'] = Variable<int>(dwellTimeMs.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StopsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('sequence: $sequence, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('markedAt: $markedAt, ')
          ..write('arrivalAt: $arrivalAt, ')
          ..write('departureAt: $departureAt, ')
          ..write('dwellTimeMs: $dwellTimeMs, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $IncidentsTable extends Incidents
    with TableInfo<$IncidentsTable, IncidentEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncidentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LOW'),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    timestamp,
    latitude,
    longitude,
    accuracy,
    type,
    severity,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'incidents';
  @override
  VerificationContext validateIntegrity(
    Insertable<IncidentEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IncidentEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncidentEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $IncidentsTable createAlias(String alias) {
    return $IncidentsTable(attachedDatabase, alias);
  }
}

class IncidentEntry extends DataClass implements Insertable<IncidentEntry> {
  final int id;
  final String tripId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String type;
  final String severity;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  const IncidentEntry({
    required this.id,
    required this.tripId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.type,
    required this.severity,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    map['type'] = Variable<String>(type);
    map['severity'] = Variable<String>(severity);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  IncidentsCompanion toCompanion(bool nullToAbsent) {
    return IncidentsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      timestamp: Value(timestamp),
      latitude: Value(latitude),
      longitude: Value(longitude),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
      type: Value(type),
      severity: Value(severity),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory IncidentEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncidentEntry(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      type: serializer.fromJson<String>(json['type']),
      severity: serializer.fromJson<String>(json['severity']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<String>(tripId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracy': serializer.toJson<double?>(accuracy),
      'type': serializer.toJson<String>(type),
      'severity': serializer.toJson<String>(severity),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  IncidentEntry copyWith({
    int? id,
    String? tripId,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    Value<double?> accuracy = const Value.absent(),
    String? type,
    String? severity,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => IncidentEntry(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    timestamp: timestamp ?? this.timestamp,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    accuracy: accuracy.present ? accuracy.value : this.accuracy,
    type: type ?? this.type,
    severity: severity ?? this.severity,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  IncidentEntry copyWithCompanion(IncidentsCompanion data) {
    return IncidentEntry(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      type: data.type.present ? data.type.value : this.type,
      severity: data.severity.present ? data.severity.value : this.severity,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncidentEntry(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('type: $type, ')
          ..write('severity: $severity, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    timestamp,
    latitude,
    longitude,
    accuracy,
    type,
    severity,
    description,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncidentEntry &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.timestamp == this.timestamp &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracy == this.accuracy &&
          other.type == this.type &&
          other.severity == this.severity &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class IncidentsCompanion extends UpdateCompanion<IncidentEntry> {
  final Value<int> id;
  final Value<String> tripId;
  final Value<DateTime> timestamp;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> accuracy;
  final Value<String> type;
  final Value<String> severity;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const IncidentsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.type = const Value.absent(),
    this.severity = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  IncidentsCompanion.insert({
    this.id = const Value.absent(),
    required String tripId,
    this.timestamp = const Value.absent(),
    required double latitude,
    required double longitude,
    this.accuracy = const Value.absent(),
    required String type,
    this.severity = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : tripId = Value(tripId),
       latitude = Value(latitude),
       longitude = Value(longitude),
       type = Value(type);
  static Insertable<IncidentEntry> custom({
    Expression<int>? id,
    Expression<String>? tripId,
    Expression<DateTime>? timestamp,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracy,
    Expression<String>? type,
    Expression<String>? severity,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (timestamp != null) 'timestamp': timestamp,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (type != null) 'type': type,
      if (severity != null) 'severity': severity,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  IncidentsCompanion copyWith({
    Value<int>? id,
    Value<String>? tripId,
    Value<DateTime>? timestamp,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double?>? accuracy,
    Value<String>? type,
    Value<String>? severity,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return IncidentsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncidentsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('type: $type, ')
          ..write('severity: $severity, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, AttachmentEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _stopIdMeta = const VerificationMeta('stopId');
  @override
  late final GeneratedColumn<int> stopId = GeneratedColumn<int>(
    'stop_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stops (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _incidentIdMeta = const VerificationMeta(
    'incidentId',
  );
  @override
  late final GeneratedColumn<int> incidentId = GeneratedColumn<int>(
    'incident_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES incidents (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    stopId,
    incidentId,
    type,
    filePath,
    timestamp,
    latitude,
    longitude,
    fileSizeBytes,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('stop_id')) {
      context.handle(
        _stopIdMeta,
        stopId.isAcceptableOrUnknown(data['stop_id']!, _stopIdMeta),
      );
    }
    if (data.containsKey('incident_id')) {
      context.handle(
        _incidentIdMeta,
        incidentId.isAcceptableOrUnknown(data['incident_id']!, _incidentIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      stopId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stop_id'],
      ),
      incidentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}incident_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class AttachmentEntry extends DataClass implements Insertable<AttachmentEntry> {
  final int id;
  final String tripId;
  final int? stopId;
  final int? incidentId;
  final String type;
  final String filePath;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final int? fileSizeBytes;
  final String? notes;
  final DateTime createdAt;
  const AttachmentEntry({
    required this.id,
    required this.tripId,
    this.stopId,
    this.incidentId,
    required this.type,
    required this.filePath,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.fileSizeBytes,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<String>(tripId);
    if (!nullToAbsent || stopId != null) {
      map['stop_id'] = Variable<int>(stopId);
    }
    if (!nullToAbsent || incidentId != null) {
      map['incident_id'] = Variable<int>(incidentId);
    }
    map['type'] = Variable<String>(type);
    map['file_path'] = Variable<String>(filePath);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || fileSizeBytes != null) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      stopId: stopId == null && nullToAbsent
          ? const Value.absent()
          : Value(stopId),
      incidentId: incidentId == null && nullToAbsent
          ? const Value.absent()
          : Value(incidentId),
      type: Value(type),
      filePath: Value(filePath),
      timestamp: Value(timestamp),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      fileSizeBytes: fileSizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSizeBytes),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory AttachmentEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentEntry(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      stopId: serializer.fromJson<int?>(json['stopId']),
      incidentId: serializer.fromJson<int?>(json['incidentId']),
      type: serializer.fromJson<String>(json['type']),
      filePath: serializer.fromJson<String>(json['filePath']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      fileSizeBytes: serializer.fromJson<int?>(json['fileSizeBytes']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<String>(tripId),
      'stopId': serializer.toJson<int?>(stopId),
      'incidentId': serializer.toJson<int?>(incidentId),
      'type': serializer.toJson<String>(type),
      'filePath': serializer.toJson<String>(filePath),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'fileSizeBytes': serializer.toJson<int?>(fileSizeBytes),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AttachmentEntry copyWith({
    int? id,
    String? tripId,
    Value<int?> stopId = const Value.absent(),
    Value<int?> incidentId = const Value.absent(),
    String? type,
    String? filePath,
    DateTime? timestamp,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<int?> fileSizeBytes = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => AttachmentEntry(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    stopId: stopId.present ? stopId.value : this.stopId,
    incidentId: incidentId.present ? incidentId.value : this.incidentId,
    type: type ?? this.type,
    filePath: filePath ?? this.filePath,
    timestamp: timestamp ?? this.timestamp,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    fileSizeBytes: fileSizeBytes.present
        ? fileSizeBytes.value
        : this.fileSizeBytes,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  AttachmentEntry copyWithCompanion(AttachmentsCompanion data) {
    return AttachmentEntry(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      stopId: data.stopId.present ? data.stopId.value : this.stopId,
      incidentId: data.incidentId.present
          ? data.incidentId.value
          : this.incidentId,
      type: data.type.present ? data.type.value : this.type,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentEntry(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('stopId: $stopId, ')
          ..write('incidentId: $incidentId, ')
          ..write('type: $type, ')
          ..write('filePath: $filePath, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    stopId,
    incidentId,
    type,
    filePath,
    timestamp,
    latitude,
    longitude,
    fileSizeBytes,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentEntry &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.stopId == this.stopId &&
          other.incidentId == this.incidentId &&
          other.type == this.type &&
          other.filePath == this.filePath &&
          other.timestamp == this.timestamp &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class AttachmentsCompanion extends UpdateCompanion<AttachmentEntry> {
  final Value<int> id;
  final Value<String> tripId;
  final Value<int?> stopId;
  final Value<int?> incidentId;
  final Value<String> type;
  final Value<String> filePath;
  final Value<DateTime> timestamp;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<int?> fileSizeBytes;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.stopId = const Value.absent(),
    this.incidentId = const Value.absent(),
    this.type = const Value.absent(),
    this.filePath = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    this.id = const Value.absent(),
    required String tripId,
    this.stopId = const Value.absent(),
    this.incidentId = const Value.absent(),
    required String type,
    required String filePath,
    this.timestamp = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : tripId = Value(tripId),
       type = Value(type),
       filePath = Value(filePath);
  static Insertable<AttachmentEntry> custom({
    Expression<int>? id,
    Expression<String>? tripId,
    Expression<int>? stopId,
    Expression<int>? incidentId,
    Expression<String>? type,
    Expression<String>? filePath,
    Expression<DateTime>? timestamp,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? fileSizeBytes,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (stopId != null) 'stop_id': stopId,
      if (incidentId != null) 'incident_id': incidentId,
      if (type != null) 'type': type,
      if (filePath != null) 'file_path': filePath,
      if (timestamp != null) 'timestamp': timestamp,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AttachmentsCompanion copyWith({
    Value<int>? id,
    Value<String>? tripId,
    Value<int?>? stopId,
    Value<int?>? incidentId,
    Value<String>? type,
    Value<String>? filePath,
    Value<DateTime>? timestamp,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<int?>? fileSizeBytes,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      stopId: stopId ?? this.stopId,
      incidentId: incidentId ?? this.incidentId,
      type: type ?? this.type,
      filePath: filePath ?? this.filePath,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (stopId.present) {
      map['stop_id'] = Variable<int>(stopId.value);
    }
    if (incidentId.present) {
      map['incident_id'] = Variable<int>(incidentId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('stopId: $stopId, ')
          ..write('incidentId: $incidentId, ')
          ..write('type: $type, ')
          ..write('filePath: $filePath, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReferenceRoutesTable extends ReferenceRoutes
    with TableInfo<$ReferenceRoutesTable, ReferenceRouteEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReferenceRoutesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _lineIdMeta = const VerificationMeta('lineId');
  @override
  late final GeneratedColumn<int> lineId = GeneratedColumn<int>(
    'line_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lines (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _branchIdMeta = const VerificationMeta(
    'branchId',
  );
  @override
  late final GeneratedColumn<int> branchId = GeneratedColumn<int>(
    'branch_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES branches (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _geoJsonDataMeta = const VerificationMeta(
    'geoJsonData',
  );
  @override
  late final GeneratedColumn<String> geoJsonData = GeneratedColumn<String>(
    'geo_json_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lineId,
    branchId,
    direction,
    name,
    format,
    geoJsonData,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reference_routes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReferenceRouteEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('line_id')) {
      context.handle(
        _lineIdMeta,
        lineId.isAcceptableOrUnknown(data['line_id']!, _lineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lineIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(
        _branchIdMeta,
        branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('geo_json_data')) {
      context.handle(
        _geoJsonDataMeta,
        geoJsonData.isAcceptableOrUnknown(
          data['geo_json_data']!,
          _geoJsonDataMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_geoJsonDataMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReferenceRouteEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReferenceRouteEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lineId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_id'],
      )!,
      branchId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}branch_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      geoJsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geo_json_data'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReferenceRoutesTable createAlias(String alias) {
    return $ReferenceRoutesTable(attachedDatabase, alias);
  }
}

class ReferenceRouteEntry extends DataClass
    implements Insertable<ReferenceRouteEntry> {
  final int id;
  final int lineId;
  final int branchId;
  final String direction;
  final String name;
  final String format;
  final String geoJsonData;
  final DateTime createdAt;
  const ReferenceRouteEntry({
    required this.id,
    required this.lineId,
    required this.branchId,
    required this.direction,
    required this.name,
    required this.format,
    required this.geoJsonData,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['line_id'] = Variable<int>(lineId);
    map['branch_id'] = Variable<int>(branchId);
    map['direction'] = Variable<String>(direction);
    map['name'] = Variable<String>(name);
    map['format'] = Variable<String>(format);
    map['geo_json_data'] = Variable<String>(geoJsonData);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReferenceRoutesCompanion toCompanion(bool nullToAbsent) {
    return ReferenceRoutesCompanion(
      id: Value(id),
      lineId: Value(lineId),
      branchId: Value(branchId),
      direction: Value(direction),
      name: Value(name),
      format: Value(format),
      geoJsonData: Value(geoJsonData),
      createdAt: Value(createdAt),
    );
  }

  factory ReferenceRouteEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReferenceRouteEntry(
      id: serializer.fromJson<int>(json['id']),
      lineId: serializer.fromJson<int>(json['lineId']),
      branchId: serializer.fromJson<int>(json['branchId']),
      direction: serializer.fromJson<String>(json['direction']),
      name: serializer.fromJson<String>(json['name']),
      format: serializer.fromJson<String>(json['format']),
      geoJsonData: serializer.fromJson<String>(json['geoJsonData']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lineId': serializer.toJson<int>(lineId),
      'branchId': serializer.toJson<int>(branchId),
      'direction': serializer.toJson<String>(direction),
      'name': serializer.toJson<String>(name),
      'format': serializer.toJson<String>(format),
      'geoJsonData': serializer.toJson<String>(geoJsonData),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReferenceRouteEntry copyWith({
    int? id,
    int? lineId,
    int? branchId,
    String? direction,
    String? name,
    String? format,
    String? geoJsonData,
    DateTime? createdAt,
  }) => ReferenceRouteEntry(
    id: id ?? this.id,
    lineId: lineId ?? this.lineId,
    branchId: branchId ?? this.branchId,
    direction: direction ?? this.direction,
    name: name ?? this.name,
    format: format ?? this.format,
    geoJsonData: geoJsonData ?? this.geoJsonData,
    createdAt: createdAt ?? this.createdAt,
  );
  ReferenceRouteEntry copyWithCompanion(ReferenceRoutesCompanion data) {
    return ReferenceRouteEntry(
      id: data.id.present ? data.id.value : this.id,
      lineId: data.lineId.present ? data.lineId.value : this.lineId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      direction: data.direction.present ? data.direction.value : this.direction,
      name: data.name.present ? data.name.value : this.name,
      format: data.format.present ? data.format.value : this.format,
      geoJsonData: data.geoJsonData.present
          ? data.geoJsonData.value
          : this.geoJsonData,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceRouteEntry(')
          ..write('id: $id, ')
          ..write('lineId: $lineId, ')
          ..write('branchId: $branchId, ')
          ..write('direction: $direction, ')
          ..write('name: $name, ')
          ..write('format: $format, ')
          ..write('geoJsonData: $geoJsonData, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lineId,
    branchId,
    direction,
    name,
    format,
    geoJsonData,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferenceRouteEntry &&
          other.id == this.id &&
          other.lineId == this.lineId &&
          other.branchId == this.branchId &&
          other.direction == this.direction &&
          other.name == this.name &&
          other.format == this.format &&
          other.geoJsonData == this.geoJsonData &&
          other.createdAt == this.createdAt);
}

class ReferenceRoutesCompanion extends UpdateCompanion<ReferenceRouteEntry> {
  final Value<int> id;
  final Value<int> lineId;
  final Value<int> branchId;
  final Value<String> direction;
  final Value<String> name;
  final Value<String> format;
  final Value<String> geoJsonData;
  final Value<DateTime> createdAt;
  const ReferenceRoutesCompanion({
    this.id = const Value.absent(),
    this.lineId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.direction = const Value.absent(),
    this.name = const Value.absent(),
    this.format = const Value.absent(),
    this.geoJsonData = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReferenceRoutesCompanion.insert({
    this.id = const Value.absent(),
    required int lineId,
    required int branchId,
    required String direction,
    required String name,
    required String format,
    required String geoJsonData,
    this.createdAt = const Value.absent(),
  }) : lineId = Value(lineId),
       branchId = Value(branchId),
       direction = Value(direction),
       name = Value(name),
       format = Value(format),
       geoJsonData = Value(geoJsonData);
  static Insertable<ReferenceRouteEntry> custom({
    Expression<int>? id,
    Expression<int>? lineId,
    Expression<int>? branchId,
    Expression<String>? direction,
    Expression<String>? name,
    Expression<String>? format,
    Expression<String>? geoJsonData,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lineId != null) 'line_id': lineId,
      if (branchId != null) 'branch_id': branchId,
      if (direction != null) 'direction': direction,
      if (name != null) 'name': name,
      if (format != null) 'format': format,
      if (geoJsonData != null) 'geo_json_data': geoJsonData,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReferenceRoutesCompanion copyWith({
    Value<int>? id,
    Value<int>? lineId,
    Value<int>? branchId,
    Value<String>? direction,
    Value<String>? name,
    Value<String>? format,
    Value<String>? geoJsonData,
    Value<DateTime>? createdAt,
  }) {
    return ReferenceRoutesCompanion(
      id: id ?? this.id,
      lineId: lineId ?? this.lineId,
      branchId: branchId ?? this.branchId,
      direction: direction ?? this.direction,
      name: name ?? this.name,
      format: format ?? this.format,
      geoJsonData: geoJsonData ?? this.geoJsonData,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lineId.present) {
      map['line_id'] = Variable<int>(lineId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<int>(branchId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (geoJsonData.present) {
      map['geo_json_data'] = Variable<String>(geoJsonData.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReferenceRoutesCompanion(')
          ..write('id: $id, ')
          ..write('lineId: $lineId, ')
          ..write('branchId: $branchId, ')
          ..write('direction: $direction, ')
          ..write('name: $name, ')
          ..write('format: $format, ')
          ..write('geoJsonData: $geoJsonData, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $OfflineMapRegionsTable extends OfflineMapRegions
    with TableInfo<$OfflineMapRegionsTable, OfflineMapRegionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineMapRegionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minZoomMeta = const VerificationMeta(
    'minZoom',
  );
  @override
  late final GeneratedColumn<int> minZoom = GeneratedColumn<int>(
    'min_zoom',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxZoomMeta = const VerificationMeta(
    'maxZoom',
  );
  @override
  late final GeneratedColumn<int> maxZoom = GeneratedColumn<int>(
    'max_zoom',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minLatMeta = const VerificationMeta('minLat');
  @override
  late final GeneratedColumn<double> minLat = GeneratedColumn<double>(
    'min_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minLngMeta = const VerificationMeta('minLng');
  @override
  late final GeneratedColumn<double> minLng = GeneratedColumn<double>(
    'min_lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxLatMeta = const VerificationMeta('maxLat');
  @override
  late final GeneratedColumn<double> maxLat = GeneratedColumn<double>(
    'max_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxLngMeta = const VerificationMeta('maxLng');
  @override
  late final GeneratedColumn<double> maxLng = GeneratedColumn<double>(
    'max_lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mbTilesPathMeta = const VerificationMeta(
    'mbTilesPath',
  );
  @override
  late final GeneratedColumn<String> mbTilesPath = GeneratedColumn<String>(
    'mb_tiles_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDownloadedMeta = const VerificationMeta(
    'isDownloaded',
  );
  @override
  late final GeneratedColumn<bool> isDownloaded = GeneratedColumn<bool>(
    'is_downloaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_downloaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    minZoom,
    maxZoom,
    minLat,
    minLng,
    maxLat,
    maxLng,
    mbTilesPath,
    sizeBytes,
    isDownloaded,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_map_regions';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineMapRegionEntry> instance, {
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
    if (data.containsKey('min_zoom')) {
      context.handle(
        _minZoomMeta,
        minZoom.isAcceptableOrUnknown(data['min_zoom']!, _minZoomMeta),
      );
    } else if (isInserting) {
      context.missing(_minZoomMeta);
    }
    if (data.containsKey('max_zoom')) {
      context.handle(
        _maxZoomMeta,
        maxZoom.isAcceptableOrUnknown(data['max_zoom']!, _maxZoomMeta),
      );
    } else if (isInserting) {
      context.missing(_maxZoomMeta);
    }
    if (data.containsKey('min_lat')) {
      context.handle(
        _minLatMeta,
        minLat.isAcceptableOrUnknown(data['min_lat']!, _minLatMeta),
      );
    } else if (isInserting) {
      context.missing(_minLatMeta);
    }
    if (data.containsKey('min_lng')) {
      context.handle(
        _minLngMeta,
        minLng.isAcceptableOrUnknown(data['min_lng']!, _minLngMeta),
      );
    } else if (isInserting) {
      context.missing(_minLngMeta);
    }
    if (data.containsKey('max_lat')) {
      context.handle(
        _maxLatMeta,
        maxLat.isAcceptableOrUnknown(data['max_lat']!, _maxLatMeta),
      );
    } else if (isInserting) {
      context.missing(_maxLatMeta);
    }
    if (data.containsKey('max_lng')) {
      context.handle(
        _maxLngMeta,
        maxLng.isAcceptableOrUnknown(data['max_lng']!, _maxLngMeta),
      );
    } else if (isInserting) {
      context.missing(_maxLngMeta);
    }
    if (data.containsKey('mb_tiles_path')) {
      context.handle(
        _mbTilesPathMeta,
        mbTilesPath.isAcceptableOrUnknown(
          data['mb_tiles_path']!,
          _mbTilesPathMeta,
        ),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('is_downloaded')) {
      context.handle(
        _isDownloadedMeta,
        isDownloaded.isAcceptableOrUnknown(
          data['is_downloaded']!,
          _isDownloadedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineMapRegionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineMapRegionEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      minZoom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_zoom'],
      )!,
      maxZoom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_zoom'],
      )!,
      minLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_lat'],
      )!,
      minLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_lng'],
      )!,
      maxLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_lat'],
      )!,
      maxLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_lng'],
      )!,
      mbTilesPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mb_tiles_path'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      isDownloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_downloaded'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OfflineMapRegionsTable createAlias(String alias) {
    return $OfflineMapRegionsTable(attachedDatabase, alias);
  }
}

class OfflineMapRegionEntry extends DataClass
    implements Insertable<OfflineMapRegionEntry> {
  final int id;
  final String name;
  final int minZoom;
  final int maxZoom;
  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;
  final String? mbTilesPath;
  final int? sizeBytes;
  final bool isDownloaded;
  final DateTime createdAt;
  const OfflineMapRegionEntry({
    required this.id,
    required this.name,
    required this.minZoom,
    required this.maxZoom,
    required this.minLat,
    required this.minLng,
    required this.maxLat,
    required this.maxLng,
    this.mbTilesPath,
    this.sizeBytes,
    required this.isDownloaded,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['min_zoom'] = Variable<int>(minZoom);
    map['max_zoom'] = Variable<int>(maxZoom);
    map['min_lat'] = Variable<double>(minLat);
    map['min_lng'] = Variable<double>(minLng);
    map['max_lat'] = Variable<double>(maxLat);
    map['max_lng'] = Variable<double>(maxLng);
    if (!nullToAbsent || mbTilesPath != null) {
      map['mb_tiles_path'] = Variable<String>(mbTilesPath);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    map['is_downloaded'] = Variable<bool>(isDownloaded);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OfflineMapRegionsCompanion toCompanion(bool nullToAbsent) {
    return OfflineMapRegionsCompanion(
      id: Value(id),
      name: Value(name),
      minZoom: Value(minZoom),
      maxZoom: Value(maxZoom),
      minLat: Value(minLat),
      minLng: Value(minLng),
      maxLat: Value(maxLat),
      maxLng: Value(maxLng),
      mbTilesPath: mbTilesPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mbTilesPath),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      isDownloaded: Value(isDownloaded),
      createdAt: Value(createdAt),
    );
  }

  factory OfflineMapRegionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineMapRegionEntry(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      minZoom: serializer.fromJson<int>(json['minZoom']),
      maxZoom: serializer.fromJson<int>(json['maxZoom']),
      minLat: serializer.fromJson<double>(json['minLat']),
      minLng: serializer.fromJson<double>(json['minLng']),
      maxLat: serializer.fromJson<double>(json['maxLat']),
      maxLng: serializer.fromJson<double>(json['maxLng']),
      mbTilesPath: serializer.fromJson<String?>(json['mbTilesPath']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      isDownloaded: serializer.fromJson<bool>(json['isDownloaded']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'minZoom': serializer.toJson<int>(minZoom),
      'maxZoom': serializer.toJson<int>(maxZoom),
      'minLat': serializer.toJson<double>(minLat),
      'minLng': serializer.toJson<double>(minLng),
      'maxLat': serializer.toJson<double>(maxLat),
      'maxLng': serializer.toJson<double>(maxLng),
      'mbTilesPath': serializer.toJson<String?>(mbTilesPath),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'isDownloaded': serializer.toJson<bool>(isDownloaded),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OfflineMapRegionEntry copyWith({
    int? id,
    String? name,
    int? minZoom,
    int? maxZoom,
    double? minLat,
    double? minLng,
    double? maxLat,
    double? maxLng,
    Value<String?> mbTilesPath = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    bool? isDownloaded,
    DateTime? createdAt,
  }) => OfflineMapRegionEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    minZoom: minZoom ?? this.minZoom,
    maxZoom: maxZoom ?? this.maxZoom,
    minLat: minLat ?? this.minLat,
    minLng: minLng ?? this.minLng,
    maxLat: maxLat ?? this.maxLat,
    maxLng: maxLng ?? this.maxLng,
    mbTilesPath: mbTilesPath.present ? mbTilesPath.value : this.mbTilesPath,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    isDownloaded: isDownloaded ?? this.isDownloaded,
    createdAt: createdAt ?? this.createdAt,
  );
  OfflineMapRegionEntry copyWithCompanion(OfflineMapRegionsCompanion data) {
    return OfflineMapRegionEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      minZoom: data.minZoom.present ? data.minZoom.value : this.minZoom,
      maxZoom: data.maxZoom.present ? data.maxZoom.value : this.maxZoom,
      minLat: data.minLat.present ? data.minLat.value : this.minLat,
      minLng: data.minLng.present ? data.minLng.value : this.minLng,
      maxLat: data.maxLat.present ? data.maxLat.value : this.maxLat,
      maxLng: data.maxLng.present ? data.maxLng.value : this.maxLng,
      mbTilesPath: data.mbTilesPath.present
          ? data.mbTilesPath.value
          : this.mbTilesPath,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      isDownloaded: data.isDownloaded.present
          ? data.isDownloaded.value
          : this.isDownloaded,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineMapRegionEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('minLat: $minLat, ')
          ..write('minLng: $minLng, ')
          ..write('maxLat: $maxLat, ')
          ..write('maxLng: $maxLng, ')
          ..write('mbTilesPath: $mbTilesPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    minZoom,
    maxZoom,
    minLat,
    minLng,
    maxLat,
    maxLng,
    mbTilesPath,
    sizeBytes,
    isDownloaded,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineMapRegionEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.minZoom == this.minZoom &&
          other.maxZoom == this.maxZoom &&
          other.minLat == this.minLat &&
          other.minLng == this.minLng &&
          other.maxLat == this.maxLat &&
          other.maxLng == this.maxLng &&
          other.mbTilesPath == this.mbTilesPath &&
          other.sizeBytes == this.sizeBytes &&
          other.isDownloaded == this.isDownloaded &&
          other.createdAt == this.createdAt);
}

class OfflineMapRegionsCompanion
    extends UpdateCompanion<OfflineMapRegionEntry> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> minZoom;
  final Value<int> maxZoom;
  final Value<double> minLat;
  final Value<double> minLng;
  final Value<double> maxLat;
  final Value<double> maxLng;
  final Value<String?> mbTilesPath;
  final Value<int?> sizeBytes;
  final Value<bool> isDownloaded;
  final Value<DateTime> createdAt;
  const OfflineMapRegionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.minZoom = const Value.absent(),
    this.maxZoom = const Value.absent(),
    this.minLat = const Value.absent(),
    this.minLng = const Value.absent(),
    this.maxLat = const Value.absent(),
    this.maxLng = const Value.absent(),
    this.mbTilesPath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OfflineMapRegionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int minZoom,
    required int maxZoom,
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    this.mbTilesPath = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.isDownloaded = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       minZoom = Value(minZoom),
       maxZoom = Value(maxZoom),
       minLat = Value(minLat),
       minLng = Value(minLng),
       maxLat = Value(maxLat),
       maxLng = Value(maxLng);
  static Insertable<OfflineMapRegionEntry> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? minZoom,
    Expression<int>? maxZoom,
    Expression<double>? minLat,
    Expression<double>? minLng,
    Expression<double>? maxLat,
    Expression<double>? maxLng,
    Expression<String>? mbTilesPath,
    Expression<int>? sizeBytes,
    Expression<bool>? isDownloaded,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (minZoom != null) 'min_zoom': minZoom,
      if (maxZoom != null) 'max_zoom': maxZoom,
      if (minLat != null) 'min_lat': minLat,
      if (minLng != null) 'min_lng': minLng,
      if (maxLat != null) 'max_lat': maxLat,
      if (maxLng != null) 'max_lng': maxLng,
      if (mbTilesPath != null) 'mb_tiles_path': mbTilesPath,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (isDownloaded != null) 'is_downloaded': isDownloaded,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OfflineMapRegionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? minZoom,
    Value<int>? maxZoom,
    Value<double>? minLat,
    Value<double>? minLng,
    Value<double>? maxLat,
    Value<double>? maxLng,
    Value<String?>? mbTilesPath,
    Value<int?>? sizeBytes,
    Value<bool>? isDownloaded,
    Value<DateTime>? createdAt,
  }) {
    return OfflineMapRegionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      minLat: minLat ?? this.minLat,
      minLng: minLng ?? this.minLng,
      maxLat: maxLat ?? this.maxLat,
      maxLng: maxLng ?? this.maxLng,
      mbTilesPath: mbTilesPath ?? this.mbTilesPath,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      createdAt: createdAt ?? this.createdAt,
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
    if (minZoom.present) {
      map['min_zoom'] = Variable<int>(minZoom.value);
    }
    if (maxZoom.present) {
      map['max_zoom'] = Variable<int>(maxZoom.value);
    }
    if (minLat.present) {
      map['min_lat'] = Variable<double>(minLat.value);
    }
    if (minLng.present) {
      map['min_lng'] = Variable<double>(minLng.value);
    }
    if (maxLat.present) {
      map['max_lat'] = Variable<double>(maxLat.value);
    }
    if (maxLng.present) {
      map['max_lng'] = Variable<double>(maxLng.value);
    }
    if (mbTilesPath.present) {
      map['mb_tiles_path'] = Variable<String>(mbTilesPath.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (isDownloaded.present) {
      map['is_downloaded'] = Variable<bool>(isDownloaded.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineMapRegionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('minLat: $minLat, ')
          ..write('minLng: $minLng, ')
          ..write('maxLat: $maxLat, ')
          ..write('maxLng: $maxLng, ')
          ..write('mbTilesPath: $mbTilesPath, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('isDownloaded: $isDownloaded, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingEntry extends DataClass implements Insertable<SettingEntry> {
  final String key;
  final String value;
  const SettingEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingEntry copyWith({String? key, String? value}) =>
      SettingEntry(key: key ?? this.key, value: value ?? this.value);
  SettingEntry copyWithCompanion(SettingsCompanion data) {
    return SettingEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LinesTable lines = $LinesTable(this);
  late final $BranchesTable branches = $BranchesTable(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $TrackPointsTable trackPoints = $TrackPointsTable(this);
  late final $StopsTable stops = $StopsTable(this);
  late final $IncidentsTable incidents = $IncidentsTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $ReferenceRoutesTable referenceRoutes = $ReferenceRoutesTable(
    this,
  );
  late final $OfflineMapRegionsTable offlineMapRegions =
      $OfflineMapRegionsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    lines,
    branches,
    trips,
    trackPoints,
    stops,
    incidents,
    attachments,
    referenceRoutes,
    offlineMapRegions,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'lines',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('branches', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'trips',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('track_points', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'trips',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('stops', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'trips',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('incidents', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'trips',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attachments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stops',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attachments', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'incidents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attachments', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'lines',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reference_routes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'branches',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reference_routes', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LinesTableCreateCompanionBuilder =
    LinesCompanion Function({
      Value<int> id,
      required String number,
      required String name,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$LinesTableUpdateCompanionBuilder =
    LinesCompanion Function({
      Value<int> id,
      Value<String> number,
      Value<String> name,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$LinesTableReferences
    extends BaseReferences<_$AppDatabase, $LinesTable, LineEntry> {
  $$LinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BranchesTable, List<BranchEntry>>
  _branchesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.branches,
    aliasName: $_aliasNameGenerator(db.lines.id, db.branches.lineId),
  );

  $$BranchesTableProcessedTableManager get branchesRefs {
    final manager = $$BranchesTableTableManager(
      $_db,
      $_db.branches,
    ).filter((f) => f.lineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_branchesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TripsTable, List<TripEntry>> _tripsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.trips,
    aliasName: $_aliasNameGenerator(db.lines.id, db.trips.lineId),
  );

  $$TripsTableProcessedTableManager get tripsRefs {
    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.lineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tripsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReferenceRoutesTable, List<ReferenceRouteEntry>>
  _referenceRoutesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.referenceRoutes,
    aliasName: $_aliasNameGenerator(db.lines.id, db.referenceRoutes.lineId),
  );

  $$ReferenceRoutesTableProcessedTableManager get referenceRoutesRefs {
    final manager = $$ReferenceRoutesTableTableManager(
      $_db,
      $_db.referenceRoutes,
    ).filter((f) => f.lineId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _referenceRoutesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LinesTableFilterComposer extends Composer<_$AppDatabase, $LinesTable> {
  $$LinesTableFilterComposer({
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

  ColumnFilters<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> branchesRefs(
    Expression<bool> Function($$BranchesTableFilterComposer f) f,
  ) {
    final $$BranchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.lineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableFilterComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tripsRefs(
    Expression<bool> Function($$TripsTableFilterComposer f) f,
  ) {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.lineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> referenceRoutesRefs(
    Expression<bool> Function($$ReferenceRoutesTableFilterComposer f) f,
  ) {
    final $$ReferenceRoutesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.referenceRoutes,
      getReferencedColumn: (t) => t.lineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferenceRoutesTableFilterComposer(
            $db: $db,
            $table: $db.referenceRoutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LinesTableOrderingComposer
    extends Composer<_$AppDatabase, $LinesTable> {
  $$LinesTableOrderingComposer({
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

  ColumnOrderings<String> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LinesTable> {
  $$LinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> branchesRefs<T extends Object>(
    Expression<T> Function($$BranchesTableAnnotationComposer a) f,
  ) {
    final $$BranchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.lineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableAnnotationComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tripsRefs<T extends Object>(
    Expression<T> Function($$TripsTableAnnotationComposer a) f,
  ) {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.lineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> referenceRoutesRefs<T extends Object>(
    Expression<T> Function($$ReferenceRoutesTableAnnotationComposer a) f,
  ) {
    final $$ReferenceRoutesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.referenceRoutes,
      getReferencedColumn: (t) => t.lineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferenceRoutesTableAnnotationComposer(
            $db: $db,
            $table: $db.referenceRoutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LinesTable,
          LineEntry,
          $$LinesTableFilterComposer,
          $$LinesTableOrderingComposer,
          $$LinesTableAnnotationComposer,
          $$LinesTableCreateCompanionBuilder,
          $$LinesTableUpdateCompanionBuilder,
          (LineEntry, $$LinesTableReferences),
          LineEntry,
          PrefetchHooks Function({
            bool branchesRefs,
            bool tripsRefs,
            bool referenceRoutesRefs,
          })
        > {
  $$LinesTableTableManager(_$AppDatabase db, $LinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> number = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LinesCompanion(
                id: id,
                number: number,
                name: name,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String number,
                required String name,
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LinesCompanion.insert(
                id: id,
                number: number,
                name: name,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$LinesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                branchesRefs = false,
                tripsRefs = false,
                referenceRoutesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (branchesRefs) db.branches,
                    if (tripsRefs) db.trips,
                    if (referenceRoutesRefs) db.referenceRoutes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (branchesRefs)
                        await $_getPrefetchedData<
                          LineEntry,
                          $LinesTable,
                          BranchEntry
                        >(
                          currentTable: table,
                          referencedTable: $$LinesTableReferences
                              ._branchesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LinesTableReferences(
                                db,
                                table,
                                p0,
                              ).branchesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.lineId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tripsRefs)
                        await $_getPrefetchedData<
                          LineEntry,
                          $LinesTable,
                          TripEntry
                        >(
                          currentTable: table,
                          referencedTable: $$LinesTableReferences
                              ._tripsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LinesTableReferences(db, table, p0).tripsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.lineId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (referenceRoutesRefs)
                        await $_getPrefetchedData<
                          LineEntry,
                          $LinesTable,
                          ReferenceRouteEntry
                        >(
                          currentTable: table,
                          referencedTable: $$LinesTableReferences
                              ._referenceRoutesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LinesTableReferences(
                                db,
                                table,
                                p0,
                              ).referenceRoutesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.lineId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LinesTable,
      LineEntry,
      $$LinesTableFilterComposer,
      $$LinesTableOrderingComposer,
      $$LinesTableAnnotationComposer,
      $$LinesTableCreateCompanionBuilder,
      $$LinesTableUpdateCompanionBuilder,
      (LineEntry, $$LinesTableReferences),
      LineEntry,
      PrefetchHooks Function({
        bool branchesRefs,
        bool tripsRefs,
        bool referenceRoutesRefs,
      })
    >;
typedef $$BranchesTableCreateCompanionBuilder =
    BranchesCompanion Function({
      Value<int> id,
      required int lineId,
      required String name,
      Value<String?> description,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$BranchesTableUpdateCompanionBuilder =
    BranchesCompanion Function({
      Value<int> id,
      Value<int> lineId,
      Value<String> name,
      Value<String?> description,
      Value<bool> active,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$BranchesTableReferences
    extends BaseReferences<_$AppDatabase, $BranchesTable, BranchEntry> {
  $$BranchesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LinesTable _lineIdTable(_$AppDatabase db) => db.lines.createAlias(
    $_aliasNameGenerator(db.branches.lineId, db.lines.id),
  );

  $$LinesTableProcessedTableManager get lineId {
    final $_column = $_itemColumn<int>('line_id')!;

    final manager = $$LinesTableTableManager(
      $_db,
      $_db.lines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TripsTable, List<TripEntry>> _tripsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.trips,
    aliasName: $_aliasNameGenerator(db.branches.id, db.trips.branchId),
  );

  $$TripsTableProcessedTableManager get tripsRefs {
    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.branchId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tripsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReferenceRoutesTable, List<ReferenceRouteEntry>>
  _referenceRoutesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.referenceRoutes,
    aliasName: $_aliasNameGenerator(
      db.branches.id,
      db.referenceRoutes.branchId,
    ),
  );

  $$ReferenceRoutesTableProcessedTableManager get referenceRoutesRefs {
    final manager = $$ReferenceRoutesTableTableManager(
      $_db,
      $_db.referenceRoutes,
    ).filter((f) => f.branchId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _referenceRoutesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BranchesTableFilterComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LinesTableFilterComposer get lineId {
    final $$LinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lineId,
      referencedTable: $db.lines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinesTableFilterComposer(
            $db: $db,
            $table: $db.lines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> tripsRefs(
    Expression<bool> Function($$TripsTableFilterComposer f) f,
  ) {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.branchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> referenceRoutesRefs(
    Expression<bool> Function($$ReferenceRoutesTableFilterComposer f) f,
  ) {
    final $$ReferenceRoutesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.referenceRoutes,
      getReferencedColumn: (t) => t.branchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferenceRoutesTableFilterComposer(
            $db: $db,
            $table: $db.referenceRoutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BranchesTableOrderingComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LinesTableOrderingComposer get lineId {
    final $$LinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lineId,
      referencedTable: $db.lines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinesTableOrderingComposer(
            $db: $db,
            $table: $db.lines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BranchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BranchesTable> {
  $$BranchesTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LinesTableAnnotationComposer get lineId {
    final $$LinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lineId,
      referencedTable: $db.lines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinesTableAnnotationComposer(
            $db: $db,
            $table: $db.lines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> tripsRefs<T extends Object>(
    Expression<T> Function($$TripsTableAnnotationComposer a) f,
  ) {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.branchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> referenceRoutesRefs<T extends Object>(
    Expression<T> Function($$ReferenceRoutesTableAnnotationComposer a) f,
  ) {
    final $$ReferenceRoutesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.referenceRoutes,
      getReferencedColumn: (t) => t.branchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferenceRoutesTableAnnotationComposer(
            $db: $db,
            $table: $db.referenceRoutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BranchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BranchesTable,
          BranchEntry,
          $$BranchesTableFilterComposer,
          $$BranchesTableOrderingComposer,
          $$BranchesTableAnnotationComposer,
          $$BranchesTableCreateCompanionBuilder,
          $$BranchesTableUpdateCompanionBuilder,
          (BranchEntry, $$BranchesTableReferences),
          BranchEntry,
          PrefetchHooks Function({
            bool lineId,
            bool tripsRefs,
            bool referenceRoutesRefs,
          })
        > {
  $$BranchesTableTableManager(_$AppDatabase db, $BranchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BranchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BranchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BranchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> lineId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BranchesCompanion(
                id: id,
                lineId: lineId,
                name: name,
                description: description,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int lineId,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BranchesCompanion.insert(
                id: id,
                lineId: lineId,
                name: name,
                description: description,
                active: active,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BranchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                lineId = false,
                tripsRefs = false,
                referenceRoutesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tripsRefs) db.trips,
                    if (referenceRoutesRefs) db.referenceRoutes,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (lineId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lineId,
                                    referencedTable: $$BranchesTableReferences
                                        ._lineIdTable(db),
                                    referencedColumn: $$BranchesTableReferences
                                        ._lineIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tripsRefs)
                        await $_getPrefetchedData<
                          BranchEntry,
                          $BranchesTable,
                          TripEntry
                        >(
                          currentTable: table,
                          referencedTable: $$BranchesTableReferences
                              ._tripsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BranchesTableReferences(
                                db,
                                table,
                                p0,
                              ).tripsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.branchId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (referenceRoutesRefs)
                        await $_getPrefetchedData<
                          BranchEntry,
                          $BranchesTable,
                          ReferenceRouteEntry
                        >(
                          currentTable: table,
                          referencedTable: $$BranchesTableReferences
                              ._referenceRoutesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BranchesTableReferences(
                                db,
                                table,
                                p0,
                              ).referenceRoutesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.branchId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BranchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BranchesTable,
      BranchEntry,
      $$BranchesTableFilterComposer,
      $$BranchesTableOrderingComposer,
      $$BranchesTableAnnotationComposer,
      $$BranchesTableCreateCompanionBuilder,
      $$BranchesTableUpdateCompanionBuilder,
      (BranchEntry, $$BranchesTableReferences),
      BranchEntry,
      PrefetchHooks Function({
        bool lineId,
        bool tripsRefs,
        bool referenceRoutesRefs,
      })
    >;
typedef $$TripsTableCreateCompanionBuilder =
    TripsCompanion Function({
      required String id,
      required int lineId,
      required int branchId,
      required String direction,
      Value<String?> internalNumber,
      Value<String?> domain,
      Value<String?> driverName,
      Value<String?> notes,
      Value<String> status,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> durationMs,
      Value<double> distanceMeters,
      Value<int> movingTimeMs,
      Value<int> stoppedTimeMs,
      Value<double> averageSpeedKmh,
      Value<double> maxSpeedKmh,
      Value<int> pointCount,
      Value<int> stopCount,
      Value<int> incidentCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$TripsTableUpdateCompanionBuilder =
    TripsCompanion Function({
      Value<String> id,
      Value<int> lineId,
      Value<int> branchId,
      Value<String> direction,
      Value<String?> internalNumber,
      Value<String?> domain,
      Value<String?> driverName,
      Value<String?> notes,
      Value<String> status,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> durationMs,
      Value<double> distanceMeters,
      Value<int> movingTimeMs,
      Value<int> stoppedTimeMs,
      Value<double> averageSpeedKmh,
      Value<double> maxSpeedKmh,
      Value<int> pointCount,
      Value<int> stopCount,
      Value<int> incidentCount,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TripsTableReferences
    extends BaseReferences<_$AppDatabase, $TripsTable, TripEntry> {
  $$TripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LinesTable _lineIdTable(_$AppDatabase db) =>
      db.lines.createAlias($_aliasNameGenerator(db.trips.lineId, db.lines.id));

  $$LinesTableProcessedTableManager get lineId {
    final $_column = $_itemColumn<int>('line_id')!;

    final manager = $$LinesTableTableManager(
      $_db,
      $_db.lines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BranchesTable _branchIdTable(_$AppDatabase db) => db.branches
      .createAlias($_aliasNameGenerator(db.trips.branchId, db.branches.id));

  $$BranchesTableProcessedTableManager get branchId {
    final $_column = $_itemColumn<int>('branch_id')!;

    final manager = $$BranchesTableTableManager(
      $_db,
      $_db.branches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_branchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TrackPointsTable, List<TrackPointEntry>>
  _trackPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.trackPoints,
    aliasName: $_aliasNameGenerator(db.trips.id, db.trackPoints.tripId),
  );

  $$TrackPointsTableProcessedTableManager get trackPointsRefs {
    final manager = $$TrackPointsTableTableManager(
      $_db,
      $_db.trackPoints,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StopsTable, List<StopEntry>> _stopsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.stops,
    aliasName: $_aliasNameGenerator(db.trips.id, db.stops.tripId),
  );

  $$StopsTableProcessedTableManager get stopsRefs {
    final manager = $$StopsTableTableManager(
      $_db,
      $_db.stops,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stopsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$IncidentsTable, List<IncidentEntry>>
  _incidentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.incidents,
    aliasName: $_aliasNameGenerator(db.trips.id, db.incidents.tripId),
  );

  $$IncidentsTableProcessedTableManager get incidentsRefs {
    final manager = $$IncidentsTableTableManager(
      $_db,
      $_db.incidents,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_incidentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<AttachmentEntry>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: $_aliasNameGenerator(db.trips.id, db.attachments.tripId),
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get internalNumber => $composableBuilder(
    column: $table.internalNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movingTimeMs => $composableBuilder(
    column: $table.movingTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stoppedTimeMs => $composableBuilder(
    column: $table.stoppedTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageSpeedKmh => $composableBuilder(
    column: $table.averageSpeedKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxSpeedKmh => $composableBuilder(
    column: $table.maxSpeedKmh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pointCount => $composableBuilder(
    column: $table.pointCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stopCount => $composableBuilder(
    column: $table.stopCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get incidentCount => $composableBuilder(
    column: $table.incidentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LinesTableFilterComposer get lineId {
    final $$LinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lineId,
      referencedTable: $db.lines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinesTableFilterComposer(
            $db: $db,
            $table: $db.lines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BranchesTableFilterComposer get branchId {
    final $$BranchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableFilterComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> trackPointsRefs(
    Expression<bool> Function($$TrackPointsTableFilterComposer f) f,
  ) {
    final $$TrackPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackPoints,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackPointsTableFilterComposer(
            $db: $db,
            $table: $db.trackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> stopsRefs(
    Expression<bool> Function($$StopsTableFilterComposer f) f,
  ) {
    final $$StopsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableFilterComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> incidentsRefs(
    Expression<bool> Function($$IncidentsTableFilterComposer f) f,
  ) {
    final $$IncidentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incidents,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncidentsTableFilterComposer(
            $db: $db,
            $table: $db.incidents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get internalNumber => $composableBuilder(
    column: $table.internalNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domain => $composableBuilder(
    column: $table.domain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingTimeMs => $composableBuilder(
    column: $table.movingTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stoppedTimeMs => $composableBuilder(
    column: $table.stoppedTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageSpeedKmh => $composableBuilder(
    column: $table.averageSpeedKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxSpeedKmh => $composableBuilder(
    column: $table.maxSpeedKmh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointCount => $composableBuilder(
    column: $table.pointCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stopCount => $composableBuilder(
    column: $table.stopCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get incidentCount => $composableBuilder(
    column: $table.incidentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LinesTableOrderingComposer get lineId {
    final $$LinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lineId,
      referencedTable: $db.lines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinesTableOrderingComposer(
            $db: $db,
            $table: $db.lines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BranchesTableOrderingComposer get branchId {
    final $$BranchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableOrderingComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get internalNumber => $composableBuilder(
    column: $table.internalNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get domain =>
      $composableBuilder(column: $table.domain, builder: (column) => column);

  GeneratedColumn<String> get driverName => $composableBuilder(
    column: $table.driverName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get movingTimeMs => $composableBuilder(
    column: $table.movingTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stoppedTimeMs => $composableBuilder(
    column: $table.stoppedTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageSpeedKmh => $composableBuilder(
    column: $table.averageSpeedKmh,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxSpeedKmh => $composableBuilder(
    column: $table.maxSpeedKmh,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pointCount => $composableBuilder(
    column: $table.pointCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stopCount =>
      $composableBuilder(column: $table.stopCount, builder: (column) => column);

  GeneratedColumn<int> get incidentCount => $composableBuilder(
    column: $table.incidentCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$LinesTableAnnotationComposer get lineId {
    final $$LinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lineId,
      referencedTable: $db.lines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinesTableAnnotationComposer(
            $db: $db,
            $table: $db.lines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BranchesTableAnnotationComposer get branchId {
    final $$BranchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableAnnotationComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> trackPointsRefs<T extends Object>(
    Expression<T> Function($$TrackPointsTableAnnotationComposer a) f,
  ) {
    final $$TrackPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackPoints,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TrackPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.trackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> stopsRefs<T extends Object>(
    Expression<T> Function($$StopsTableAnnotationComposer a) f,
  ) {
    final $$StopsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableAnnotationComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> incidentsRefs<T extends Object>(
    Expression<T> Function($$IncidentsTableAnnotationComposer a) f,
  ) {
    final $$IncidentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incidents,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncidentsTableAnnotationComposer(
            $db: $db,
            $table: $db.incidents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripsTable,
          TripEntry,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (TripEntry, $$TripsTableReferences),
          TripEntry,
          PrefetchHooks Function({
            bool lineId,
            bool branchId,
            bool trackPointsRefs,
            bool stopsRefs,
            bool incidentsRefs,
            bool attachmentsRefs,
          })
        > {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> lineId = const Value.absent(),
                Value<int> branchId = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String?> internalNumber = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                Value<String?> driverName = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<int> movingTimeMs = const Value.absent(),
                Value<int> stoppedTimeMs = const Value.absent(),
                Value<double> averageSpeedKmh = const Value.absent(),
                Value<double> maxSpeedKmh = const Value.absent(),
                Value<int> pointCount = const Value.absent(),
                Value<int> stopCount = const Value.absent(),
                Value<int> incidentCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion(
                id: id,
                lineId: lineId,
                branchId: branchId,
                direction: direction,
                internalNumber: internalNumber,
                domain: domain,
                driverName: driverName,
                notes: notes,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                durationMs: durationMs,
                distanceMeters: distanceMeters,
                movingTimeMs: movingTimeMs,
                stoppedTimeMs: stoppedTimeMs,
                averageSpeedKmh: averageSpeedKmh,
                maxSpeedKmh: maxSpeedKmh,
                pointCount: pointCount,
                stopCount: stopCount,
                incidentCount: incidentCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int lineId,
                required int branchId,
                required String direction,
                Value<String?> internalNumber = const Value.absent(),
                Value<String?> domain = const Value.absent(),
                Value<String?> driverName = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<int> movingTimeMs = const Value.absent(),
                Value<int> stoppedTimeMs = const Value.absent(),
                Value<double> averageSpeedKmh = const Value.absent(),
                Value<double> maxSpeedKmh = const Value.absent(),
                Value<int> pointCount = const Value.absent(),
                Value<int> stopCount = const Value.absent(),
                Value<int> incidentCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion.insert(
                id: id,
                lineId: lineId,
                branchId: branchId,
                direction: direction,
                internalNumber: internalNumber,
                domain: domain,
                driverName: driverName,
                notes: notes,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                durationMs: durationMs,
                distanceMeters: distanceMeters,
                movingTimeMs: movingTimeMs,
                stoppedTimeMs: stoppedTimeMs,
                averageSpeedKmh: averageSpeedKmh,
                maxSpeedKmh: maxSpeedKmh,
                pointCount: pointCount,
                stopCount: stopCount,
                incidentCount: incidentCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TripsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                lineId = false,
                branchId = false,
                trackPointsRefs = false,
                stopsRefs = false,
                incidentsRefs = false,
                attachmentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (trackPointsRefs) db.trackPoints,
                    if (stopsRefs) db.stops,
                    if (incidentsRefs) db.incidents,
                    if (attachmentsRefs) db.attachments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (lineId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lineId,
                                    referencedTable: $$TripsTableReferences
                                        ._lineIdTable(db),
                                    referencedColumn: $$TripsTableReferences
                                        ._lineIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (branchId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.branchId,
                                    referencedTable: $$TripsTableReferences
                                        ._branchIdTable(db),
                                    referencedColumn: $$TripsTableReferences
                                        ._branchIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (trackPointsRefs)
                        await $_getPrefetchedData<
                          TripEntry,
                          $TripsTable,
                          TrackPointEntry
                        >(
                          currentTable: table,
                          referencedTable: $$TripsTableReferences
                              ._trackPointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TripsTableReferences(
                                db,
                                table,
                                p0,
                              ).trackPointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tripId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (stopsRefs)
                        await $_getPrefetchedData<
                          TripEntry,
                          $TripsTable,
                          StopEntry
                        >(
                          currentTable: table,
                          referencedTable: $$TripsTableReferences
                              ._stopsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TripsTableReferences(db, table, p0).stopsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tripId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (incidentsRefs)
                        await $_getPrefetchedData<
                          TripEntry,
                          $TripsTable,
                          IncidentEntry
                        >(
                          currentTable: table,
                          referencedTable: $$TripsTableReferences
                              ._incidentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TripsTableReferences(
                                db,
                                table,
                                p0,
                              ).incidentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tripId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attachmentsRefs)
                        await $_getPrefetchedData<
                          TripEntry,
                          $TripsTable,
                          AttachmentEntry
                        >(
                          currentTable: table,
                          referencedTable: $$TripsTableReferences
                              ._attachmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TripsTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tripId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripsTable,
      TripEntry,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (TripEntry, $$TripsTableReferences),
      TripEntry,
      PrefetchHooks Function({
        bool lineId,
        bool branchId,
        bool trackPointsRefs,
        bool stopsRefs,
        bool incidentsRefs,
        bool attachmentsRefs,
      })
    >;
typedef $$TrackPointsTableCreateCompanionBuilder =
    TrackPointsCompanion Function({
      Value<int> id,
      required String tripId,
      Value<DateTime> timestamp,
      Value<int?> elapsedRealtimeNanos,
      required double latitude,
      required double longitude,
      Value<double?> altitude,
      Value<double?> accuracy,
      Value<double?> speedMps,
      Value<double?> bearingDegrees,
      Value<String?> provider,
      Value<String> quality,
      Value<bool> isAccepted,
      Value<DateTime> createdAt,
    });
typedef $$TrackPointsTableUpdateCompanionBuilder =
    TrackPointsCompanion Function({
      Value<int> id,
      Value<String> tripId,
      Value<DateTime> timestamp,
      Value<int?> elapsedRealtimeNanos,
      Value<double> latitude,
      Value<double> longitude,
      Value<double?> altitude,
      Value<double?> accuracy,
      Value<double?> speedMps,
      Value<double?> bearingDegrees,
      Value<String?> provider,
      Value<String> quality,
      Value<bool> isAccepted,
      Value<DateTime> createdAt,
    });

final class $$TrackPointsTableReferences
    extends BaseReferences<_$AppDatabase, $TrackPointsTable, TrackPointEntry> {
  $$TrackPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips.createAlias(
    $_aliasNameGenerator(db.trackPoints.tripId, db.trips.id),
  );

  $$TripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<String>('trip_id')!;

    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackPointsTableFilterComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableFilterComposer({
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

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedRealtimeNanos => $composableBuilder(
    column: $table.elapsedRealtimeNanos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bearingDegrees => $composableBuilder(
    column: $table.bearingDegrees,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAccepted => $composableBuilder(
    column: $table.isAccepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedRealtimeNanos => $composableBuilder(
    column: $table.elapsedRealtimeNanos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bearingDegrees => $composableBuilder(
    column: $table.bearingDegrees,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAccepted => $composableBuilder(
    column: $table.isAccepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TrackPointsTable> {
  $$TrackPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get elapsedRealtimeNanos => $composableBuilder(
    column: $table.elapsedRealtimeNanos,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);

  GeneratedColumn<double> get bearingDegrees => $composableBuilder(
    column: $table.bearingDegrees,
    builder: (column) => column,
  );

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<bool> get isAccepted => $composableBuilder(
    column: $table.isAccepted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackPointsTable,
          TrackPointEntry,
          $$TrackPointsTableFilterComposer,
          $$TrackPointsTableOrderingComposer,
          $$TrackPointsTableAnnotationComposer,
          $$TrackPointsTableCreateCompanionBuilder,
          $$TrackPointsTableUpdateCompanionBuilder,
          (TrackPointEntry, $$TrackPointsTableReferences),
          TrackPointEntry,
          PrefetchHooks Function({bool tripId})
        > {
  $$TrackPointsTableTableManager(_$AppDatabase db, $TrackPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TrackPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TrackPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TrackPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int?> elapsedRealtimeNanos = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
                Value<double?> bearingDegrees = const Value.absent(),
                Value<String?> provider = const Value.absent(),
                Value<String> quality = const Value.absent(),
                Value<bool> isAccepted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TrackPointsCompanion(
                id: id,
                tripId: tripId,
                timestamp: timestamp,
                elapsedRealtimeNanos: elapsedRealtimeNanos,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                accuracy: accuracy,
                speedMps: speedMps,
                bearingDegrees: bearingDegrees,
                provider: provider,
                quality: quality,
                isAccepted: isAccepted,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tripId,
                Value<DateTime> timestamp = const Value.absent(),
                Value<int?> elapsedRealtimeNanos = const Value.absent(),
                required double latitude,
                required double longitude,
                Value<double?> altitude = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
                Value<double?> bearingDegrees = const Value.absent(),
                Value<String?> provider = const Value.absent(),
                Value<String> quality = const Value.absent(),
                Value<bool> isAccepted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TrackPointsCompanion.insert(
                id: id,
                tripId: tripId,
                timestamp: timestamp,
                elapsedRealtimeNanos: elapsedRealtimeNanos,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                accuracy: accuracy,
                speedMps: speedMps,
                bearingDegrees: bearingDegrees,
                provider: provider,
                quality: quality,
                isAccepted: isAccepted,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TrackPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tripId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (tripId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tripId,
                                referencedTable: $$TrackPointsTableReferences
                                    ._tripIdTable(db),
                                referencedColumn: $$TrackPointsTableReferences
                                    ._tripIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackPointsTable,
      TrackPointEntry,
      $$TrackPointsTableFilterComposer,
      $$TrackPointsTableOrderingComposer,
      $$TrackPointsTableAnnotationComposer,
      $$TrackPointsTableCreateCompanionBuilder,
      $$TrackPointsTableUpdateCompanionBuilder,
      (TrackPointEntry, $$TrackPointsTableReferences),
      TrackPointEntry,
      PrefetchHooks Function({bool tripId})
    >;
typedef $$StopsTableCreateCompanionBuilder =
    StopsCompanion Function({
      Value<int> id,
      required String tripId,
      Value<int> sequence,
      required double latitude,
      required double longitude,
      Value<double?> accuracy,
      Value<DateTime> markedAt,
      Value<DateTime?> arrivalAt,
      Value<DateTime?> departureAt,
      Value<int?> dwellTimeMs,
      Value<String?> name,
      Value<String?> code,
      Value<String> status,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$StopsTableUpdateCompanionBuilder =
    StopsCompanion Function({
      Value<int> id,
      Value<String> tripId,
      Value<int> sequence,
      Value<double> latitude,
      Value<double> longitude,
      Value<double?> accuracy,
      Value<DateTime> markedAt,
      Value<DateTime?> arrivalAt,
      Value<DateTime?> departureAt,
      Value<int?> dwellTimeMs,
      Value<String?> name,
      Value<String?> code,
      Value<String> status,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$StopsTableReferences
    extends BaseReferences<_$AppDatabase, $StopsTable, StopEntry> {
  $$StopsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) =>
      db.trips.createAlias($_aliasNameGenerator(db.stops.tripId, db.trips.id));

  $$TripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<String>('trip_id')!;

    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<AttachmentEntry>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: $_aliasNameGenerator(db.stops.id, db.attachments.stopId),
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.stopId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StopsTableFilterComposer extends Composer<_$AppDatabase, $StopsTable> {
  $$StopsTableFilterComposer({
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

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get markedAt => $composableBuilder(
    column: $table.markedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get arrivalAt => $composableBuilder(
    column: $table.arrivalAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get departureAt => $composableBuilder(
    column: $table.departureAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dwellTimeMs => $composableBuilder(
    column: $table.dwellTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.stopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StopsTableOrderingComposer
    extends Composer<_$AppDatabase, $StopsTable> {
  $$StopsTableOrderingComposer({
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

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get markedAt => $composableBuilder(
    column: $table.markedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get arrivalAt => $composableBuilder(
    column: $table.arrivalAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get departureAt => $composableBuilder(
    column: $table.departureAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dwellTimeMs => $composableBuilder(
    column: $table.dwellTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StopsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StopsTable> {
  $$StopsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<DateTime> get markedAt =>
      $composableBuilder(column: $table.markedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get arrivalAt =>
      $composableBuilder(column: $table.arrivalAt, builder: (column) => column);

  GeneratedColumn<DateTime> get departureAt => $composableBuilder(
    column: $table.departureAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dwellTimeMs => $composableBuilder(
    column: $table.dwellTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.stopId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StopsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StopsTable,
          StopEntry,
          $$StopsTableFilterComposer,
          $$StopsTableOrderingComposer,
          $$StopsTableAnnotationComposer,
          $$StopsTableCreateCompanionBuilder,
          $$StopsTableUpdateCompanionBuilder,
          (StopEntry, $$StopsTableReferences),
          StopEntry,
          PrefetchHooks Function({bool tripId, bool attachmentsRefs})
        > {
  $$StopsTableTableManager(_$AppDatabase db, $StopsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StopsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StopsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StopsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<DateTime> markedAt = const Value.absent(),
                Value<DateTime?> arrivalAt = const Value.absent(),
                Value<DateTime?> departureAt = const Value.absent(),
                Value<int?> dwellTimeMs = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StopsCompanion(
                id: id,
                tripId: tripId,
                sequence: sequence,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                markedAt: markedAt,
                arrivalAt: arrivalAt,
                departureAt: departureAt,
                dwellTimeMs: dwellTimeMs,
                name: name,
                code: code,
                status: status,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tripId,
                Value<int> sequence = const Value.absent(),
                required double latitude,
                required double longitude,
                Value<double?> accuracy = const Value.absent(),
                Value<DateTime> markedAt = const Value.absent(),
                Value<DateTime?> arrivalAt = const Value.absent(),
                Value<DateTime?> departureAt = const Value.absent(),
                Value<int?> dwellTimeMs = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String?> code = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => StopsCompanion.insert(
                id: id,
                tripId: tripId,
                sequence: sequence,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                markedAt: markedAt,
                arrivalAt: arrivalAt,
                departureAt: departureAt,
                dwellTimeMs: dwellTimeMs,
                name: name,
                code: code,
                status: status,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$StopsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({tripId = false, attachmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (attachmentsRefs) db.attachments],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (tripId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tripId,
                                referencedTable: $$StopsTableReferences
                                    ._tripIdTable(db),
                                referencedColumn: $$StopsTableReferences
                                    ._tripIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (attachmentsRefs)
                    await $_getPrefetchedData<
                      StopEntry,
                      $StopsTable,
                      AttachmentEntry
                    >(
                      currentTable: table,
                      referencedTable: $$StopsTableReferences
                          ._attachmentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$StopsTableReferences(db, table, p0).attachmentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.stopId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StopsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StopsTable,
      StopEntry,
      $$StopsTableFilterComposer,
      $$StopsTableOrderingComposer,
      $$StopsTableAnnotationComposer,
      $$StopsTableCreateCompanionBuilder,
      $$StopsTableUpdateCompanionBuilder,
      (StopEntry, $$StopsTableReferences),
      StopEntry,
      PrefetchHooks Function({bool tripId, bool attachmentsRefs})
    >;
typedef $$IncidentsTableCreateCompanionBuilder =
    IncidentsCompanion Function({
      Value<int> id,
      required String tripId,
      Value<DateTime> timestamp,
      required double latitude,
      required double longitude,
      Value<double?> accuracy,
      required String type,
      Value<String> severity,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$IncidentsTableUpdateCompanionBuilder =
    IncidentsCompanion Function({
      Value<int> id,
      Value<String> tripId,
      Value<DateTime> timestamp,
      Value<double> latitude,
      Value<double> longitude,
      Value<double?> accuracy,
      Value<String> type,
      Value<String> severity,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$IncidentsTableReferences
    extends BaseReferences<_$AppDatabase, $IncidentsTable, IncidentEntry> {
  $$IncidentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips.createAlias(
    $_aliasNameGenerator(db.incidents.tripId, db.trips.id),
  );

  $$TripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<String>('trip_id')!;

    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AttachmentsTable, List<AttachmentEntry>>
  _attachmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.attachments,
    aliasName: $_aliasNameGenerator(db.incidents.id, db.attachments.incidentId),
  );

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager(
      $_db,
      $_db.attachments,
    ).filter((f) => f.incidentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$IncidentsTableFilterComposer
    extends Composer<_$AppDatabase, $IncidentsTable> {
  $$IncidentsTableFilterComposer({
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

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> attachmentsRefs(
    Expression<bool> Function($$AttachmentsTableFilterComposer f) f,
  ) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.incidentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableFilterComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IncidentsTableOrderingComposer
    extends Composer<_$AppDatabase, $IncidentsTable> {
  $$IncidentsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncidentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncidentsTable> {
  $$IncidentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> attachmentsRefs<T extends Object>(
    Expression<T> Function($$AttachmentsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attachments,
      getReferencedColumn: (t) => t.incidentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttachmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.attachments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IncidentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncidentsTable,
          IncidentEntry,
          $$IncidentsTableFilterComposer,
          $$IncidentsTableOrderingComposer,
          $$IncidentsTableAnnotationComposer,
          $$IncidentsTableCreateCompanionBuilder,
          $$IncidentsTableUpdateCompanionBuilder,
          (IncidentEntry, $$IncidentsTableReferences),
          IncidentEntry,
          PrefetchHooks Function({bool tripId, bool attachmentsRefs})
        > {
  $$IncidentsTableTableManager(_$AppDatabase db, $IncidentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncidentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncidentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncidentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => IncidentsCompanion(
                id: id,
                tripId: tripId,
                timestamp: timestamp,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                type: type,
                severity: severity,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tripId,
                Value<DateTime> timestamp = const Value.absent(),
                required double latitude,
                required double longitude,
                Value<double?> accuracy = const Value.absent(),
                required String type,
                Value<String> severity = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => IncidentsCompanion.insert(
                id: id,
                tripId: tripId,
                timestamp: timestamp,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                type: type,
                severity: severity,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IncidentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tripId = false, attachmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (attachmentsRefs) db.attachments],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (tripId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tripId,
                                referencedTable: $$IncidentsTableReferences
                                    ._tripIdTable(db),
                                referencedColumn: $$IncidentsTableReferences
                                    ._tripIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (attachmentsRefs)
                    await $_getPrefetchedData<
                      IncidentEntry,
                      $IncidentsTable,
                      AttachmentEntry
                    >(
                      currentTable: table,
                      referencedTable: $$IncidentsTableReferences
                          ._attachmentsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$IncidentsTableReferences(
                            db,
                            table,
                            p0,
                          ).attachmentsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.incidentId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$IncidentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncidentsTable,
      IncidentEntry,
      $$IncidentsTableFilterComposer,
      $$IncidentsTableOrderingComposer,
      $$IncidentsTableAnnotationComposer,
      $$IncidentsTableCreateCompanionBuilder,
      $$IncidentsTableUpdateCompanionBuilder,
      (IncidentEntry, $$IncidentsTableReferences),
      IncidentEntry,
      PrefetchHooks Function({bool tripId, bool attachmentsRefs})
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<int> id,
      required String tripId,
      Value<int?> stopId,
      Value<int?> incidentId,
      required String type,
      required String filePath,
      Value<DateTime> timestamp,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<int?> fileSizeBytes,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<int> id,
      Value<String> tripId,
      Value<int?> stopId,
      Value<int?> incidentId,
      Value<String> type,
      Value<String> filePath,
      Value<DateTime> timestamp,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<int?> fileSizeBytes,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });

final class $$AttachmentsTableReferences
    extends BaseReferences<_$AppDatabase, $AttachmentsTable, AttachmentEntry> {
  $$AttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) => db.trips.createAlias(
    $_aliasNameGenerator(db.attachments.tripId, db.trips.id),
  );

  $$TripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<String>('trip_id')!;

    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StopsTable _stopIdTable(_$AppDatabase db) => db.stops.createAlias(
    $_aliasNameGenerator(db.attachments.stopId, db.stops.id),
  );

  $$StopsTableProcessedTableManager? get stopId {
    final $_column = $_itemColumn<int>('stop_id');
    if ($_column == null) return null;
    final manager = $$StopsTableTableManager(
      $_db,
      $_db.stops,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stopIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $IncidentsTable _incidentIdTable(_$AppDatabase db) =>
      db.incidents.createAlias(
        $_aliasNameGenerator(db.attachments.incidentId, db.incidents.id),
      );

  $$IncidentsTableProcessedTableManager? get incidentId {
    final $_column = $_itemColumn<int>('incident_id');
    if ($_column == null) return null;
    final manager = $$IncidentsTableTableManager(
      $_db,
      $_db.incidents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_incidentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StopsTableFilterComposer get stopId {
    final $$StopsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableFilterComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$IncidentsTableFilterComposer get incidentId {
    final $$IncidentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.incidentId,
      referencedTable: $db.incidents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncidentsTableFilterComposer(
            $db: $db,
            $table: $db.incidents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StopsTableOrderingComposer get stopId {
    final $$StopsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableOrderingComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$IncidentsTableOrderingComposer get incidentId {
    final $$IncidentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.incidentId,
      referencedTable: $db.incidents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncidentsTableOrderingComposer(
            $db: $db,
            $table: $db.incidents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StopsTableAnnotationComposer get stopId {
    final $$StopsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stopId,
      referencedTable: $db.stops,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StopsTableAnnotationComposer(
            $db: $db,
            $table: $db.stops,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$IncidentsTableAnnotationComposer get incidentId {
    final $$IncidentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.incidentId,
      referencedTable: $db.incidents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncidentsTableAnnotationComposer(
            $db: $db,
            $table: $db.incidents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          AttachmentEntry,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (AttachmentEntry, $$AttachmentsTableReferences),
          AttachmentEntry,
          PrefetchHooks Function({bool tripId, bool stopId, bool incidentId})
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<int?> stopId = const Value.absent(),
                Value<int?> incidentId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<int?> fileSizeBytes = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                tripId: tripId,
                stopId: stopId,
                incidentId: incidentId,
                type: type,
                filePath: filePath,
                timestamp: timestamp,
                latitude: latitude,
                longitude: longitude,
                fileSizeBytes: fileSizeBytes,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tripId,
                Value<int?> stopId = const Value.absent(),
                Value<int?> incidentId = const Value.absent(),
                required String type,
                required String filePath,
                Value<DateTime> timestamp = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<int?> fileSizeBytes = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                tripId: tripId,
                stopId: stopId,
                incidentId: incidentId,
                type: type,
                filePath: filePath,
                timestamp: timestamp,
                latitude: latitude,
                longitude: longitude,
                fileSizeBytes: fileSizeBytes,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttachmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({tripId = false, stopId = false, incidentId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (tripId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.tripId,
                                    referencedTable:
                                        $$AttachmentsTableReferences
                                            ._tripIdTable(db),
                                    referencedColumn:
                                        $$AttachmentsTableReferences
                                            ._tripIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (stopId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.stopId,
                                    referencedTable:
                                        $$AttachmentsTableReferences
                                            ._stopIdTable(db),
                                    referencedColumn:
                                        $$AttachmentsTableReferences
                                            ._stopIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (incidentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.incidentId,
                                    referencedTable:
                                        $$AttachmentsTableReferences
                                            ._incidentIdTable(db),
                                    referencedColumn:
                                        $$AttachmentsTableReferences
                                            ._incidentIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      AttachmentEntry,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (AttachmentEntry, $$AttachmentsTableReferences),
      AttachmentEntry,
      PrefetchHooks Function({bool tripId, bool stopId, bool incidentId})
    >;
typedef $$ReferenceRoutesTableCreateCompanionBuilder =
    ReferenceRoutesCompanion Function({
      Value<int> id,
      required int lineId,
      required int branchId,
      required String direction,
      required String name,
      required String format,
      required String geoJsonData,
      Value<DateTime> createdAt,
    });
typedef $$ReferenceRoutesTableUpdateCompanionBuilder =
    ReferenceRoutesCompanion Function({
      Value<int> id,
      Value<int> lineId,
      Value<int> branchId,
      Value<String> direction,
      Value<String> name,
      Value<String> format,
      Value<String> geoJsonData,
      Value<DateTime> createdAt,
    });

final class $$ReferenceRoutesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ReferenceRoutesTable,
          ReferenceRouteEntry
        > {
  $$ReferenceRoutesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LinesTable _lineIdTable(_$AppDatabase db) => db.lines.createAlias(
    $_aliasNameGenerator(db.referenceRoutes.lineId, db.lines.id),
  );

  $$LinesTableProcessedTableManager get lineId {
    final $_column = $_itemColumn<int>('line_id')!;

    final manager = $$LinesTableTableManager(
      $_db,
      $_db.lines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BranchesTable _branchIdTable(_$AppDatabase db) =>
      db.branches.createAlias(
        $_aliasNameGenerator(db.referenceRoutes.branchId, db.branches.id),
      );

  $$BranchesTableProcessedTableManager get branchId {
    final $_column = $_itemColumn<int>('branch_id')!;

    final manager = $$BranchesTableTableManager(
      $_db,
      $_db.branches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_branchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReferenceRoutesTableFilterComposer
    extends Composer<_$AppDatabase, $ReferenceRoutesTable> {
  $$ReferenceRoutesTableFilterComposer({
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

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get geoJsonData => $composableBuilder(
    column: $table.geoJsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LinesTableFilterComposer get lineId {
    final $$LinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lineId,
      referencedTable: $db.lines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinesTableFilterComposer(
            $db: $db,
            $table: $db.lines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BranchesTableFilterComposer get branchId {
    final $$BranchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableFilterComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReferenceRoutesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReferenceRoutesTable> {
  $$ReferenceRoutesTableOrderingComposer({
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

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geoJsonData => $composableBuilder(
    column: $table.geoJsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LinesTableOrderingComposer get lineId {
    final $$LinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lineId,
      referencedTable: $db.lines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinesTableOrderingComposer(
            $db: $db,
            $table: $db.lines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BranchesTableOrderingComposer get branchId {
    final $$BranchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableOrderingComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReferenceRoutesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReferenceRoutesTable> {
  $$ReferenceRoutesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get geoJsonData => $composableBuilder(
    column: $table.geoJsonData,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LinesTableAnnotationComposer get lineId {
    final $$LinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lineId,
      referencedTable: $db.lines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LinesTableAnnotationComposer(
            $db: $db,
            $table: $db.lines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BranchesTableAnnotationComposer get branchId {
    final $$BranchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.branchId,
      referencedTable: $db.branches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BranchesTableAnnotationComposer(
            $db: $db,
            $table: $db.branches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReferenceRoutesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReferenceRoutesTable,
          ReferenceRouteEntry,
          $$ReferenceRoutesTableFilterComposer,
          $$ReferenceRoutesTableOrderingComposer,
          $$ReferenceRoutesTableAnnotationComposer,
          $$ReferenceRoutesTableCreateCompanionBuilder,
          $$ReferenceRoutesTableUpdateCompanionBuilder,
          (ReferenceRouteEntry, $$ReferenceRoutesTableReferences),
          ReferenceRouteEntry,
          PrefetchHooks Function({bool lineId, bool branchId})
        > {
  $$ReferenceRoutesTableTableManager(
    _$AppDatabase db,
    $ReferenceRoutesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReferenceRoutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReferenceRoutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReferenceRoutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> lineId = const Value.absent(),
                Value<int> branchId = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> geoJsonData = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReferenceRoutesCompanion(
                id: id,
                lineId: lineId,
                branchId: branchId,
                direction: direction,
                name: name,
                format: format,
                geoJsonData: geoJsonData,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int lineId,
                required int branchId,
                required String direction,
                required String name,
                required String format,
                required String geoJsonData,
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReferenceRoutesCompanion.insert(
                id: id,
                lineId: lineId,
                branchId: branchId,
                direction: direction,
                name: name,
                format: format,
                geoJsonData: geoJsonData,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReferenceRoutesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({lineId = false, branchId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (lineId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.lineId,
                                referencedTable:
                                    $$ReferenceRoutesTableReferences
                                        ._lineIdTable(db),
                                referencedColumn:
                                    $$ReferenceRoutesTableReferences
                                        ._lineIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (branchId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.branchId,
                                referencedTable:
                                    $$ReferenceRoutesTableReferences
                                        ._branchIdTable(db),
                                referencedColumn:
                                    $$ReferenceRoutesTableReferences
                                        ._branchIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReferenceRoutesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReferenceRoutesTable,
      ReferenceRouteEntry,
      $$ReferenceRoutesTableFilterComposer,
      $$ReferenceRoutesTableOrderingComposer,
      $$ReferenceRoutesTableAnnotationComposer,
      $$ReferenceRoutesTableCreateCompanionBuilder,
      $$ReferenceRoutesTableUpdateCompanionBuilder,
      (ReferenceRouteEntry, $$ReferenceRoutesTableReferences),
      ReferenceRouteEntry,
      PrefetchHooks Function({bool lineId, bool branchId})
    >;
typedef $$OfflineMapRegionsTableCreateCompanionBuilder =
    OfflineMapRegionsCompanion Function({
      Value<int> id,
      required String name,
      required int minZoom,
      required int maxZoom,
      required double minLat,
      required double minLng,
      required double maxLat,
      required double maxLng,
      Value<String?> mbTilesPath,
      Value<int?> sizeBytes,
      Value<bool> isDownloaded,
      Value<DateTime> createdAt,
    });
typedef $$OfflineMapRegionsTableUpdateCompanionBuilder =
    OfflineMapRegionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> minZoom,
      Value<int> maxZoom,
      Value<double> minLat,
      Value<double> minLng,
      Value<double> maxLat,
      Value<double> maxLng,
      Value<String?> mbTilesPath,
      Value<int?> sizeBytes,
      Value<bool> isDownloaded,
      Value<DateTime> createdAt,
    });

class $$OfflineMapRegionsTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineMapRegionsTable> {
  $$OfflineMapRegionsTableFilterComposer({
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

  ColumnFilters<int> get minZoom => $composableBuilder(
    column: $table.minZoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxZoom => $composableBuilder(
    column: $table.maxZoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minLat => $composableBuilder(
    column: $table.minLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minLng => $composableBuilder(
    column: $table.minLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxLat => $composableBuilder(
    column: $table.maxLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxLng => $composableBuilder(
    column: $table.maxLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mbTilesPath => $composableBuilder(
    column: $table.mbTilesPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineMapRegionsTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineMapRegionsTable> {
  $$OfflineMapRegionsTableOrderingComposer({
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

  ColumnOrderings<int> get minZoom => $composableBuilder(
    column: $table.minZoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxZoom => $composableBuilder(
    column: $table.maxZoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minLat => $composableBuilder(
    column: $table.minLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minLng => $composableBuilder(
    column: $table.minLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxLat => $composableBuilder(
    column: $table.maxLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxLng => $composableBuilder(
    column: $table.maxLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mbTilesPath => $composableBuilder(
    column: $table.mbTilesPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineMapRegionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineMapRegionsTable> {
  $$OfflineMapRegionsTableAnnotationComposer({
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

  GeneratedColumn<int> get minZoom =>
      $composableBuilder(column: $table.minZoom, builder: (column) => column);

  GeneratedColumn<int> get maxZoom =>
      $composableBuilder(column: $table.maxZoom, builder: (column) => column);

  GeneratedColumn<double> get minLat =>
      $composableBuilder(column: $table.minLat, builder: (column) => column);

  GeneratedColumn<double> get minLng =>
      $composableBuilder(column: $table.minLng, builder: (column) => column);

  GeneratedColumn<double> get maxLat =>
      $composableBuilder(column: $table.maxLat, builder: (column) => column);

  GeneratedColumn<double> get maxLng =>
      $composableBuilder(column: $table.maxLng, builder: (column) => column);

  GeneratedColumn<String> get mbTilesPath => $composableBuilder(
    column: $table.mbTilesPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<bool> get isDownloaded => $composableBuilder(
    column: $table.isDownloaded,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OfflineMapRegionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineMapRegionsTable,
          OfflineMapRegionEntry,
          $$OfflineMapRegionsTableFilterComposer,
          $$OfflineMapRegionsTableOrderingComposer,
          $$OfflineMapRegionsTableAnnotationComposer,
          $$OfflineMapRegionsTableCreateCompanionBuilder,
          $$OfflineMapRegionsTableUpdateCompanionBuilder,
          (
            OfflineMapRegionEntry,
            BaseReferences<
              _$AppDatabase,
              $OfflineMapRegionsTable,
              OfflineMapRegionEntry
            >,
          ),
          OfflineMapRegionEntry,
          PrefetchHooks Function()
        > {
  $$OfflineMapRegionsTableTableManager(
    _$AppDatabase db,
    $OfflineMapRegionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineMapRegionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineMapRegionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineMapRegionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> minZoom = const Value.absent(),
                Value<int> maxZoom = const Value.absent(),
                Value<double> minLat = const Value.absent(),
                Value<double> minLng = const Value.absent(),
                Value<double> maxLat = const Value.absent(),
                Value<double> maxLng = const Value.absent(),
                Value<String?> mbTilesPath = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<bool> isDownloaded = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OfflineMapRegionsCompanion(
                id: id,
                name: name,
                minZoom: minZoom,
                maxZoom: maxZoom,
                minLat: minLat,
                minLng: minLng,
                maxLat: maxLat,
                maxLng: maxLng,
                mbTilesPath: mbTilesPath,
                sizeBytes: sizeBytes,
                isDownloaded: isDownloaded,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int minZoom,
                required int maxZoom,
                required double minLat,
                required double minLng,
                required double maxLat,
                required double maxLng,
                Value<String?> mbTilesPath = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<bool> isDownloaded = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OfflineMapRegionsCompanion.insert(
                id: id,
                name: name,
                minZoom: minZoom,
                maxZoom: maxZoom,
                minLat: minLat,
                minLng: minLng,
                maxLat: maxLat,
                maxLng: maxLng,
                mbTilesPath: mbTilesPath,
                sizeBytes: sizeBytes,
                isDownloaded: isDownloaded,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineMapRegionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineMapRegionsTable,
      OfflineMapRegionEntry,
      $$OfflineMapRegionsTableFilterComposer,
      $$OfflineMapRegionsTableOrderingComposer,
      $$OfflineMapRegionsTableAnnotationComposer,
      $$OfflineMapRegionsTableCreateCompanionBuilder,
      $$OfflineMapRegionsTableUpdateCompanionBuilder,
      (
        OfflineMapRegionEntry,
        BaseReferences<
          _$AppDatabase,
          $OfflineMapRegionsTable,
          OfflineMapRegionEntry
        >,
      ),
      OfflineMapRegionEntry,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingEntry,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingEntry,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingEntry>,
          ),
          SettingEntry,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingEntry,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (
        SettingEntry,
        BaseReferences<_$AppDatabase, $SettingsTable, SettingEntry>,
      ),
      SettingEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LinesTableTableManager get lines =>
      $$LinesTableTableManager(_db, _db.lines);
  $$BranchesTableTableManager get branches =>
      $$BranchesTableTableManager(_db, _db.branches);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$TrackPointsTableTableManager get trackPoints =>
      $$TrackPointsTableTableManager(_db, _db.trackPoints);
  $$StopsTableTableManager get stops =>
      $$StopsTableTableManager(_db, _db.stops);
  $$IncidentsTableTableManager get incidents =>
      $$IncidentsTableTableManager(_db, _db.incidents);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$ReferenceRoutesTableTableManager get referenceRoutes =>
      $$ReferenceRoutesTableTableManager(_db, _db.referenceRoutes);
  $$OfflineMapRegionsTableTableManager get offlineMapRegions =>
      $$OfflineMapRegionsTableTableManager(_db, _db.offlineMapRegions);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
