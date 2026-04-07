// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_patient_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FamilyInfo _$FamilyInfoFromJson(Map<String, dynamic> json) {
  return _FamilyInfo.fromJson(json);
}

/// @nodoc
mixin _$FamilyInfo {
  String get headOfFamily => throw _privateConstructorUsedError;
  String get numberOfMembers => throw _privateConstructorUsedError;
  String get familyAddress => throw _privateConstructorUsedError;
  bool get sameAddressForAll => throw _privateConstructorUsedError;

  /// Serializes this FamilyInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FamilyInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FamilyInfoCopyWith<FamilyInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilyInfoCopyWith<$Res> {
  factory $FamilyInfoCopyWith(
    FamilyInfo value,
    $Res Function(FamilyInfo) then,
  ) = _$FamilyInfoCopyWithImpl<$Res, FamilyInfo>;
  @useResult
  $Res call({
    String headOfFamily,
    String numberOfMembers,
    String familyAddress,
    bool sameAddressForAll,
  });
}

/// @nodoc
class _$FamilyInfoCopyWithImpl<$Res, $Val extends FamilyInfo>
    implements $FamilyInfoCopyWith<$Res> {
  _$FamilyInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FamilyInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? headOfFamily = null,
    Object? numberOfMembers = null,
    Object? familyAddress = null,
    Object? sameAddressForAll = null,
  }) {
    return _then(
      _value.copyWith(
            headOfFamily: null == headOfFamily
                ? _value.headOfFamily
                : headOfFamily // ignore: cast_nullable_to_non_nullable
                      as String,
            numberOfMembers: null == numberOfMembers
                ? _value.numberOfMembers
                : numberOfMembers // ignore: cast_nullable_to_non_nullable
                      as String,
            familyAddress: null == familyAddress
                ? _value.familyAddress
                : familyAddress // ignore: cast_nullable_to_non_nullable
                      as String,
            sameAddressForAll: null == sameAddressForAll
                ? _value.sameAddressForAll
                : sameAddressForAll // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FamilyInfoImplCopyWith<$Res>
    implements $FamilyInfoCopyWith<$Res> {
  factory _$$FamilyInfoImplCopyWith(
    _$FamilyInfoImpl value,
    $Res Function(_$FamilyInfoImpl) then,
  ) = __$$FamilyInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String headOfFamily,
    String numberOfMembers,
    String familyAddress,
    bool sameAddressForAll,
  });
}

/// @nodoc
class __$$FamilyInfoImplCopyWithImpl<$Res>
    extends _$FamilyInfoCopyWithImpl<$Res, _$FamilyInfoImpl>
    implements _$$FamilyInfoImplCopyWith<$Res> {
  __$$FamilyInfoImplCopyWithImpl(
    _$FamilyInfoImpl _value,
    $Res Function(_$FamilyInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FamilyInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? headOfFamily = null,
    Object? numberOfMembers = null,
    Object? familyAddress = null,
    Object? sameAddressForAll = null,
  }) {
    return _then(
      _$FamilyInfoImpl(
        headOfFamily: null == headOfFamily
            ? _value.headOfFamily
            : headOfFamily // ignore: cast_nullable_to_non_nullable
                  as String,
        numberOfMembers: null == numberOfMembers
            ? _value.numberOfMembers
            : numberOfMembers // ignore: cast_nullable_to_non_nullable
                  as String,
        familyAddress: null == familyAddress
            ? _value.familyAddress
            : familyAddress // ignore: cast_nullable_to_non_nullable
                  as String,
        sameAddressForAll: null == sameAddressForAll
            ? _value.sameAddressForAll
            : sameAddressForAll // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FamilyInfoImpl implements _FamilyInfo {
  const _$FamilyInfoImpl({
    required this.headOfFamily,
    required this.numberOfMembers,
    required this.familyAddress,
    this.sameAddressForAll = true,
  });

  factory _$FamilyInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilyInfoImplFromJson(json);

  @override
  final String headOfFamily;
  @override
  final String numberOfMembers;
  @override
  final String familyAddress;
  @override
  @JsonKey()
  final bool sameAddressForAll;

  @override
  String toString() {
    return 'FamilyInfo(headOfFamily: $headOfFamily, numberOfMembers: $numberOfMembers, familyAddress: $familyAddress, sameAddressForAll: $sameAddressForAll)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyInfoImpl &&
            (identical(other.headOfFamily, headOfFamily) ||
                other.headOfFamily == headOfFamily) &&
            (identical(other.numberOfMembers, numberOfMembers) ||
                other.numberOfMembers == numberOfMembers) &&
            (identical(other.familyAddress, familyAddress) ||
                other.familyAddress == familyAddress) &&
            (identical(other.sameAddressForAll, sameAddressForAll) ||
                other.sameAddressForAll == sameAddressForAll));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    headOfFamily,
    numberOfMembers,
    familyAddress,
    sameAddressForAll,
  );

  /// Create a copy of FamilyInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilyInfoImplCopyWith<_$FamilyInfoImpl> get copyWith =>
      __$$FamilyInfoImplCopyWithImpl<_$FamilyInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FamilyInfoImplToJson(this);
  }
}

abstract class _FamilyInfo implements FamilyInfo {
  const factory _FamilyInfo({
    required final String headOfFamily,
    required final String numberOfMembers,
    required final String familyAddress,
    final bool sameAddressForAll,
  }) = _$FamilyInfoImpl;

  factory _FamilyInfo.fromJson(Map<String, dynamic> json) =
      _$FamilyInfoImpl.fromJson;

  @override
  String get headOfFamily;
  @override
  String get numberOfMembers;
  @override
  String get familyAddress;
  @override
  bool get sameAddressForAll;

  /// Create a copy of FamilyInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FamilyInfoImplCopyWith<_$FamilyInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PatientDataModel _$PatientDataModelFromJson(Map<String, dynamic> json) {
  return _PatientDataModel.fromJson(json);
}

/// @nodoc
mixin _$PatientDataModel {
  String get id => throw _privateConstructorUsedError;
  String get patientName => throw _privateConstructorUsedError;
  String get age => throw _privateConstructorUsedError;
  String get dateOfBirth => throw _privateConstructorUsedError;
  String get gender => throw _privateConstructorUsedError;
  String get caste => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  bool get sameAsFamilyAddress => throw _privateConstructorUsedError;
  String get phoneNumber =>
      throw _privateConstructorUsedError; // Pregnancy fields
  bool get isPregnant => throw _privateConstructorUsedError;
  String get monthsOfPregnancy => throw _privateConstructorUsedError;
  String get expectedDeliveryDate =>
      throw _privateConstructorUsedError; // Photo
  String? get photoPath => throw _privateConstructorUsedError; // Medical info
  Map<String, bool> get diseases => throw _privateConstructorUsedError;
  bool get declinedHealthInfo => throw _privateConstructorUsedError;
  String get notes => throw _privateConstructorUsedError;

  /// Serializes this PatientDataModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PatientDataModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PatientDataModelCopyWith<PatientDataModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PatientDataModelCopyWith<$Res> {
  factory $PatientDataModelCopyWith(
    PatientDataModel value,
    $Res Function(PatientDataModel) then,
  ) = _$PatientDataModelCopyWithImpl<$Res, PatientDataModel>;
  @useResult
  $Res call({
    String id,
    String patientName,
    String age,
    String dateOfBirth,
    String gender,
    String caste,
    String address,
    bool sameAsFamilyAddress,
    String phoneNumber,
    bool isPregnant,
    String monthsOfPregnancy,
    String expectedDeliveryDate,
    String? photoPath,
    Map<String, bool> diseases,
    bool declinedHealthInfo,
    String notes,
  });
}

/// @nodoc
class _$PatientDataModelCopyWithImpl<$Res, $Val extends PatientDataModel>
    implements $PatientDataModelCopyWith<$Res> {
  _$PatientDataModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PatientDataModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? patientName = null,
    Object? age = null,
    Object? dateOfBirth = null,
    Object? gender = null,
    Object? caste = null,
    Object? address = null,
    Object? sameAsFamilyAddress = null,
    Object? phoneNumber = null,
    Object? isPregnant = null,
    Object? monthsOfPregnancy = null,
    Object? expectedDeliveryDate = null,
    Object? photoPath = freezed,
    Object? diseases = null,
    Object? declinedHealthInfo = null,
    Object? notes = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            patientName: null == patientName
                ? _value.patientName
                : patientName // ignore: cast_nullable_to_non_nullable
                      as String,
            age: null == age
                ? _value.age
                : age // ignore: cast_nullable_to_non_nullable
                      as String,
            dateOfBirth: null == dateOfBirth
                ? _value.dateOfBirth
                : dateOfBirth // ignore: cast_nullable_to_non_nullable
                      as String,
            gender: null == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String,
            caste: null == caste
                ? _value.caste
                : caste // ignore: cast_nullable_to_non_nullable
                      as String,
            address: null == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String,
            sameAsFamilyAddress: null == sameAsFamilyAddress
                ? _value.sameAsFamilyAddress
                : sameAsFamilyAddress // ignore: cast_nullable_to_non_nullable
                      as bool,
            phoneNumber: null == phoneNumber
                ? _value.phoneNumber
                : phoneNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            isPregnant: null == isPregnant
                ? _value.isPregnant
                : isPregnant // ignore: cast_nullable_to_non_nullable
                      as bool,
            monthsOfPregnancy: null == monthsOfPregnancy
                ? _value.monthsOfPregnancy
                : monthsOfPregnancy // ignore: cast_nullable_to_non_nullable
                      as String,
            expectedDeliveryDate: null == expectedDeliveryDate
                ? _value.expectedDeliveryDate
                : expectedDeliveryDate // ignore: cast_nullable_to_non_nullable
                      as String,
            photoPath: freezed == photoPath
                ? _value.photoPath
                : photoPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            diseases: null == diseases
                ? _value.diseases
                : diseases // ignore: cast_nullable_to_non_nullable
                      as Map<String, bool>,
            declinedHealthInfo: null == declinedHealthInfo
                ? _value.declinedHealthInfo
                : declinedHealthInfo // ignore: cast_nullable_to_non_nullable
                      as bool,
            notes: null == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PatientDataModelImplCopyWith<$Res>
    implements $PatientDataModelCopyWith<$Res> {
  factory _$$PatientDataModelImplCopyWith(
    _$PatientDataModelImpl value,
    $Res Function(_$PatientDataModelImpl) then,
  ) = __$$PatientDataModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String patientName,
    String age,
    String dateOfBirth,
    String gender,
    String caste,
    String address,
    bool sameAsFamilyAddress,
    String phoneNumber,
    bool isPregnant,
    String monthsOfPregnancy,
    String expectedDeliveryDate,
    String? photoPath,
    Map<String, bool> diseases,
    bool declinedHealthInfo,
    String notes,
  });
}

/// @nodoc
class __$$PatientDataModelImplCopyWithImpl<$Res>
    extends _$PatientDataModelCopyWithImpl<$Res, _$PatientDataModelImpl>
    implements _$$PatientDataModelImplCopyWith<$Res> {
  __$$PatientDataModelImplCopyWithImpl(
    _$PatientDataModelImpl _value,
    $Res Function(_$PatientDataModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PatientDataModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? patientName = null,
    Object? age = null,
    Object? dateOfBirth = null,
    Object? gender = null,
    Object? caste = null,
    Object? address = null,
    Object? sameAsFamilyAddress = null,
    Object? phoneNumber = null,
    Object? isPregnant = null,
    Object? monthsOfPregnancy = null,
    Object? expectedDeliveryDate = null,
    Object? photoPath = freezed,
    Object? diseases = null,
    Object? declinedHealthInfo = null,
    Object? notes = null,
  }) {
    return _then(
      _$PatientDataModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        patientName: null == patientName
            ? _value.patientName
            : patientName // ignore: cast_nullable_to_non_nullable
                  as String,
        age: null == age
            ? _value.age
            : age // ignore: cast_nullable_to_non_nullable
                  as String,
        dateOfBirth: null == dateOfBirth
            ? _value.dateOfBirth
            : dateOfBirth // ignore: cast_nullable_to_non_nullable
                  as String,
        gender: null == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String,
        caste: null == caste
            ? _value.caste
            : caste // ignore: cast_nullable_to_non_nullable
                  as String,
        address: null == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String,
        sameAsFamilyAddress: null == sameAsFamilyAddress
            ? _value.sameAsFamilyAddress
            : sameAsFamilyAddress // ignore: cast_nullable_to_non_nullable
                  as bool,
        phoneNumber: null == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        isPregnant: null == isPregnant
            ? _value.isPregnant
            : isPregnant // ignore: cast_nullable_to_non_nullable
                  as bool,
        monthsOfPregnancy: null == monthsOfPregnancy
            ? _value.monthsOfPregnancy
            : monthsOfPregnancy // ignore: cast_nullable_to_non_nullable
                  as String,
        expectedDeliveryDate: null == expectedDeliveryDate
            ? _value.expectedDeliveryDate
            : expectedDeliveryDate // ignore: cast_nullable_to_non_nullable
                  as String,
        photoPath: freezed == photoPath
            ? _value.photoPath
            : photoPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        diseases: null == diseases
            ? _value._diseases
            : diseases // ignore: cast_nullable_to_non_nullable
                  as Map<String, bool>,
        declinedHealthInfo: null == declinedHealthInfo
            ? _value.declinedHealthInfo
            : declinedHealthInfo // ignore: cast_nullable_to_non_nullable
                  as bool,
        notes: null == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PatientDataModelImpl implements _PatientDataModel {
  const _$PatientDataModelImpl({
    required this.id,
    required this.patientName,
    required this.age,
    required this.dateOfBirth,
    required this.gender,
    required this.caste,
    required this.address,
    this.sameAsFamilyAddress = true,
    required this.phoneNumber,
    this.isPregnant = false,
    this.monthsOfPregnancy = '1',
    required this.expectedDeliveryDate,
    this.photoPath,
    required final Map<String, bool> diseases,
    this.declinedHealthInfo = false,
    required this.notes,
  }) : _diseases = diseases;

  factory _$PatientDataModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PatientDataModelImplFromJson(json);

  @override
  final String id;
  @override
  final String patientName;
  @override
  final String age;
  @override
  final String dateOfBirth;
  @override
  final String gender;
  @override
  final String caste;
  @override
  final String address;
  @override
  @JsonKey()
  final bool sameAsFamilyAddress;
  @override
  final String phoneNumber;
  // Pregnancy fields
  @override
  @JsonKey()
  final bool isPregnant;
  @override
  @JsonKey()
  final String monthsOfPregnancy;
  @override
  final String expectedDeliveryDate;
  // Photo
  @override
  final String? photoPath;
  // Medical info
  final Map<String, bool> _diseases;
  // Medical info
  @override
  Map<String, bool> get diseases {
    if (_diseases is EqualUnmodifiableMapView) return _diseases;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_diseases);
  }

  @override
  @JsonKey()
  final bool declinedHealthInfo;
  @override
  final String notes;

  @override
  String toString() {
    return 'PatientDataModel(id: $id, patientName: $patientName, age: $age, dateOfBirth: $dateOfBirth, gender: $gender, caste: $caste, address: $address, sameAsFamilyAddress: $sameAsFamilyAddress, phoneNumber: $phoneNumber, isPregnant: $isPregnant, monthsOfPregnancy: $monthsOfPregnancy, expectedDeliveryDate: $expectedDeliveryDate, photoPath: $photoPath, diseases: $diseases, declinedHealthInfo: $declinedHealthInfo, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PatientDataModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.patientName, patientName) ||
                other.patientName == patientName) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.dateOfBirth, dateOfBirth) ||
                other.dateOfBirth == dateOfBirth) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.caste, caste) || other.caste == caste) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.sameAsFamilyAddress, sameAsFamilyAddress) ||
                other.sameAsFamilyAddress == sameAsFamilyAddress) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.isPregnant, isPregnant) ||
                other.isPregnant == isPregnant) &&
            (identical(other.monthsOfPregnancy, monthsOfPregnancy) ||
                other.monthsOfPregnancy == monthsOfPregnancy) &&
            (identical(other.expectedDeliveryDate, expectedDeliveryDate) ||
                other.expectedDeliveryDate == expectedDeliveryDate) &&
            (identical(other.photoPath, photoPath) ||
                other.photoPath == photoPath) &&
            const DeepCollectionEquality().equals(other._diseases, _diseases) &&
            (identical(other.declinedHealthInfo, declinedHealthInfo) ||
                other.declinedHealthInfo == declinedHealthInfo) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    patientName,
    age,
    dateOfBirth,
    gender,
    caste,
    address,
    sameAsFamilyAddress,
    phoneNumber,
    isPregnant,
    monthsOfPregnancy,
    expectedDeliveryDate,
    photoPath,
    const DeepCollectionEquality().hash(_diseases),
    declinedHealthInfo,
    notes,
  );

  /// Create a copy of PatientDataModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PatientDataModelImplCopyWith<_$PatientDataModelImpl> get copyWith =>
      __$$PatientDataModelImplCopyWithImpl<_$PatientDataModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PatientDataModelImplToJson(this);
  }
}

abstract class _PatientDataModel implements PatientDataModel {
  const factory _PatientDataModel({
    required final String id,
    required final String patientName,
    required final String age,
    required final String dateOfBirth,
    required final String gender,
    required final String caste,
    required final String address,
    final bool sameAsFamilyAddress,
    required final String phoneNumber,
    final bool isPregnant,
    final String monthsOfPregnancy,
    required final String expectedDeliveryDate,
    final String? photoPath,
    required final Map<String, bool> diseases,
    final bool declinedHealthInfo,
    required final String notes,
  }) = _$PatientDataModelImpl;

  factory _PatientDataModel.fromJson(Map<String, dynamic> json) =
      _$PatientDataModelImpl.fromJson;

  @override
  String get id;
  @override
  String get patientName;
  @override
  String get age;
  @override
  String get dateOfBirth;
  @override
  String get gender;
  @override
  String get caste;
  @override
  String get address;
  @override
  bool get sameAsFamilyAddress;
  @override
  String get phoneNumber; // Pregnancy fields
  @override
  bool get isPregnant;
  @override
  String get monthsOfPregnancy;
  @override
  String get expectedDeliveryDate; // Photo
  @override
  String? get photoPath; // Medical info
  @override
  Map<String, bool> get diseases;
  @override
  bool get declinedHealthInfo;
  @override
  String get notes;

  /// Create a copy of PatientDataModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PatientDataModelImplCopyWith<_$PatientDataModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AddPatientFormState {
  int get step => throw _privateConstructorUsedError; // 1, 2, or 3
  FamilyInfo get familyInfo => throw _privateConstructorUsedError;
  List<PatientDataModel> get patients => throw _privateConstructorUsedError;
  int get currentPatientIndex => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String get errorMessage => throw _privateConstructorUsedError;
  Map<String, String> get validationErrors =>
      throw _privateConstructorUsedError;

  /// Create a copy of AddPatientFormState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AddPatientFormStateCopyWith<AddPatientFormState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AddPatientFormStateCopyWith<$Res> {
  factory $AddPatientFormStateCopyWith(
    AddPatientFormState value,
    $Res Function(AddPatientFormState) then,
  ) = _$AddPatientFormStateCopyWithImpl<$Res, AddPatientFormState>;
  @useResult
  $Res call({
    int step,
    FamilyInfo familyInfo,
    List<PatientDataModel> patients,
    int currentPatientIndex,
    bool isLoading,
    String errorMessage,
    Map<String, String> validationErrors,
  });

  $FamilyInfoCopyWith<$Res> get familyInfo;
}

/// @nodoc
class _$AddPatientFormStateCopyWithImpl<$Res, $Val extends AddPatientFormState>
    implements $AddPatientFormStateCopyWith<$Res> {
  _$AddPatientFormStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AddPatientFormState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? step = null,
    Object? familyInfo = null,
    Object? patients = null,
    Object? currentPatientIndex = null,
    Object? isLoading = null,
    Object? errorMessage = null,
    Object? validationErrors = null,
  }) {
    return _then(
      _value.copyWith(
            step: null == step
                ? _value.step
                : step // ignore: cast_nullable_to_non_nullable
                      as int,
            familyInfo: null == familyInfo
                ? _value.familyInfo
                : familyInfo // ignore: cast_nullable_to_non_nullable
                      as FamilyInfo,
            patients: null == patients
                ? _value.patients
                : patients // ignore: cast_nullable_to_non_nullable
                      as List<PatientDataModel>,
            currentPatientIndex: null == currentPatientIndex
                ? _value.currentPatientIndex
                : currentPatientIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            errorMessage: null == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String,
            validationErrors: null == validationErrors
                ? _value.validationErrors
                : validationErrors // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
          )
          as $Val,
    );
  }

  /// Create a copy of AddPatientFormState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FamilyInfoCopyWith<$Res> get familyInfo {
    return $FamilyInfoCopyWith<$Res>(_value.familyInfo, (value) {
      return _then(_value.copyWith(familyInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AddPatientFormStateImplCopyWith<$Res>
    implements $AddPatientFormStateCopyWith<$Res> {
  factory _$$AddPatientFormStateImplCopyWith(
    _$AddPatientFormStateImpl value,
    $Res Function(_$AddPatientFormStateImpl) then,
  ) = __$$AddPatientFormStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int step,
    FamilyInfo familyInfo,
    List<PatientDataModel> patients,
    int currentPatientIndex,
    bool isLoading,
    String errorMessage,
    Map<String, String> validationErrors,
  });

  @override
  $FamilyInfoCopyWith<$Res> get familyInfo;
}

/// @nodoc
class __$$AddPatientFormStateImplCopyWithImpl<$Res>
    extends _$AddPatientFormStateCopyWithImpl<$Res, _$AddPatientFormStateImpl>
    implements _$$AddPatientFormStateImplCopyWith<$Res> {
  __$$AddPatientFormStateImplCopyWithImpl(
    _$AddPatientFormStateImpl _value,
    $Res Function(_$AddPatientFormStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AddPatientFormState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? step = null,
    Object? familyInfo = null,
    Object? patients = null,
    Object? currentPatientIndex = null,
    Object? isLoading = null,
    Object? errorMessage = null,
    Object? validationErrors = null,
  }) {
    return _then(
      _$AddPatientFormStateImpl(
        step: null == step
            ? _value.step
            : step // ignore: cast_nullable_to_non_nullable
                  as int,
        familyInfo: null == familyInfo
            ? _value.familyInfo
            : familyInfo // ignore: cast_nullable_to_non_nullable
                  as FamilyInfo,
        patients: null == patients
            ? _value._patients
            : patients // ignore: cast_nullable_to_non_nullable
                  as List<PatientDataModel>,
        currentPatientIndex: null == currentPatientIndex
            ? _value.currentPatientIndex
            : currentPatientIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        errorMessage: null == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String,
        validationErrors: null == validationErrors
            ? _value._validationErrors
            : validationErrors // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
      ),
    );
  }
}

/// @nodoc

class _$AddPatientFormStateImpl implements _AddPatientFormState {
  const _$AddPatientFormStateImpl({
    required this.step,
    required this.familyInfo,
    required final List<PatientDataModel> patients,
    required this.currentPatientIndex,
    this.isLoading = false,
    this.errorMessage = '',
    final Map<String, String> validationErrors = const {},
  }) : _patients = patients,
       _validationErrors = validationErrors;

  @override
  final int step;
  // 1, 2, or 3
  @override
  final FamilyInfo familyInfo;
  final List<PatientDataModel> _patients;
  @override
  List<PatientDataModel> get patients {
    if (_patients is EqualUnmodifiableListView) return _patients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_patients);
  }

  @override
  final int currentPatientIndex;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final String errorMessage;
  final Map<String, String> _validationErrors;
  @override
  @JsonKey()
  Map<String, String> get validationErrors {
    if (_validationErrors is EqualUnmodifiableMapView) return _validationErrors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_validationErrors);
  }

  @override
  String toString() {
    return 'AddPatientFormState(step: $step, familyInfo: $familyInfo, patients: $patients, currentPatientIndex: $currentPatientIndex, isLoading: $isLoading, errorMessage: $errorMessage, validationErrors: $validationErrors)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AddPatientFormStateImpl &&
            (identical(other.step, step) || other.step == step) &&
            (identical(other.familyInfo, familyInfo) ||
                other.familyInfo == familyInfo) &&
            const DeepCollectionEquality().equals(other._patients, _patients) &&
            (identical(other.currentPatientIndex, currentPatientIndex) ||
                other.currentPatientIndex == currentPatientIndex) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            const DeepCollectionEquality().equals(
              other._validationErrors,
              _validationErrors,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    step,
    familyInfo,
    const DeepCollectionEquality().hash(_patients),
    currentPatientIndex,
    isLoading,
    errorMessage,
    const DeepCollectionEquality().hash(_validationErrors),
  );

  /// Create a copy of AddPatientFormState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AddPatientFormStateImplCopyWith<_$AddPatientFormStateImpl> get copyWith =>
      __$$AddPatientFormStateImplCopyWithImpl<_$AddPatientFormStateImpl>(
        this,
        _$identity,
      );
}

abstract class _AddPatientFormState implements AddPatientFormState {
  const factory _AddPatientFormState({
    required final int step,
    required final FamilyInfo familyInfo,
    required final List<PatientDataModel> patients,
    required final int currentPatientIndex,
    final bool isLoading,
    final String errorMessage,
    final Map<String, String> validationErrors,
  }) = _$AddPatientFormStateImpl;

  @override
  int get step; // 1, 2, or 3
  @override
  FamilyInfo get familyInfo;
  @override
  List<PatientDataModel> get patients;
  @override
  int get currentPatientIndex;
  @override
  bool get isLoading;
  @override
  String get errorMessage;
  @override
  Map<String, String> get validationErrors;

  /// Create a copy of AddPatientFormState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AddPatientFormStateImplCopyWith<_$AddPatientFormStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PatientRegistrationPayload _$PatientRegistrationPayloadFromJson(
  Map<String, dynamic> json,
) {
  return _PatientRegistrationPayload.fromJson(json);
}

/// @nodoc
mixin _$PatientRegistrationPayload {
  FamilyInfo get familyInfo => throw _privateConstructorUsedError;
  List<PatientDataModel> get patients => throw _privateConstructorUsedError;

  /// Serializes this PatientRegistrationPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PatientRegistrationPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PatientRegistrationPayloadCopyWith<PatientRegistrationPayload>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PatientRegistrationPayloadCopyWith<$Res> {
  factory $PatientRegistrationPayloadCopyWith(
    PatientRegistrationPayload value,
    $Res Function(PatientRegistrationPayload) then,
  ) =
      _$PatientRegistrationPayloadCopyWithImpl<
        $Res,
        PatientRegistrationPayload
      >;
  @useResult
  $Res call({FamilyInfo familyInfo, List<PatientDataModel> patients});

  $FamilyInfoCopyWith<$Res> get familyInfo;
}

/// @nodoc
class _$PatientRegistrationPayloadCopyWithImpl<
  $Res,
  $Val extends PatientRegistrationPayload
>
    implements $PatientRegistrationPayloadCopyWith<$Res> {
  _$PatientRegistrationPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PatientRegistrationPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? familyInfo = null, Object? patients = null}) {
    return _then(
      _value.copyWith(
            familyInfo: null == familyInfo
                ? _value.familyInfo
                : familyInfo // ignore: cast_nullable_to_non_nullable
                      as FamilyInfo,
            patients: null == patients
                ? _value.patients
                : patients // ignore: cast_nullable_to_non_nullable
                      as List<PatientDataModel>,
          )
          as $Val,
    );
  }

  /// Create a copy of PatientRegistrationPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FamilyInfoCopyWith<$Res> get familyInfo {
    return $FamilyInfoCopyWith<$Res>(_value.familyInfo, (value) {
      return _then(_value.copyWith(familyInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PatientRegistrationPayloadImplCopyWith<$Res>
    implements $PatientRegistrationPayloadCopyWith<$Res> {
  factory _$$PatientRegistrationPayloadImplCopyWith(
    _$PatientRegistrationPayloadImpl value,
    $Res Function(_$PatientRegistrationPayloadImpl) then,
  ) = __$$PatientRegistrationPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({FamilyInfo familyInfo, List<PatientDataModel> patients});

  @override
  $FamilyInfoCopyWith<$Res> get familyInfo;
}

/// @nodoc
class __$$PatientRegistrationPayloadImplCopyWithImpl<$Res>
    extends
        _$PatientRegistrationPayloadCopyWithImpl<
          $Res,
          _$PatientRegistrationPayloadImpl
        >
    implements _$$PatientRegistrationPayloadImplCopyWith<$Res> {
  __$$PatientRegistrationPayloadImplCopyWithImpl(
    _$PatientRegistrationPayloadImpl _value,
    $Res Function(_$PatientRegistrationPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PatientRegistrationPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? familyInfo = null, Object? patients = null}) {
    return _then(
      _$PatientRegistrationPayloadImpl(
        familyInfo: null == familyInfo
            ? _value.familyInfo
            : familyInfo // ignore: cast_nullable_to_non_nullable
                  as FamilyInfo,
        patients: null == patients
            ? _value._patients
            : patients // ignore: cast_nullable_to_non_nullable
                  as List<PatientDataModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PatientRegistrationPayloadImpl implements _PatientRegistrationPayload {
  const _$PatientRegistrationPayloadImpl({
    required this.familyInfo,
    required final List<PatientDataModel> patients,
  }) : _patients = patients;

  factory _$PatientRegistrationPayloadImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$PatientRegistrationPayloadImplFromJson(json);

  @override
  final FamilyInfo familyInfo;
  final List<PatientDataModel> _patients;
  @override
  List<PatientDataModel> get patients {
    if (_patients is EqualUnmodifiableListView) return _patients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_patients);
  }

  @override
  String toString() {
    return 'PatientRegistrationPayload(familyInfo: $familyInfo, patients: $patients)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PatientRegistrationPayloadImpl &&
            (identical(other.familyInfo, familyInfo) ||
                other.familyInfo == familyInfo) &&
            const DeepCollectionEquality().equals(other._patients, _patients));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    familyInfo,
    const DeepCollectionEquality().hash(_patients),
  );

  /// Create a copy of PatientRegistrationPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PatientRegistrationPayloadImplCopyWith<_$PatientRegistrationPayloadImpl>
  get copyWith =>
      __$$PatientRegistrationPayloadImplCopyWithImpl<
        _$PatientRegistrationPayloadImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PatientRegistrationPayloadImplToJson(this);
  }
}

abstract class _PatientRegistrationPayload
    implements PatientRegistrationPayload {
  const factory _PatientRegistrationPayload({
    required final FamilyInfo familyInfo,
    required final List<PatientDataModel> patients,
  }) = _$PatientRegistrationPayloadImpl;

  factory _PatientRegistrationPayload.fromJson(Map<String, dynamic> json) =
      _$PatientRegistrationPayloadImpl.fromJson;

  @override
  FamilyInfo get familyInfo;
  @override
  List<PatientDataModel> get patients;

  /// Create a copy of PatientRegistrationPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PatientRegistrationPayloadImplCopyWith<_$PatientRegistrationPayloadImpl>
  get copyWith => throw _privateConstructorUsedError;
}
