# Firestore Integration Methods for Vehicle Damage App

## Overview
This document outlines all the new methods implemented for uploading and downloading damage reports and estimates to/from your Firestore database.

## 🔥 FirebaseFirestoreService Methods

### Damage Report Operations

#### 1. Create Damage Report
```dart
Future<String> createDamageReport({
  required String ownerId,
  required String vehicleMake,
  required String vehicleModel,
  required int vehicleYear,
  required String damageDescription,
  required File? image,
  required double estimatedCost,
  String? additionalNotes,
  List<String> imageUrls = const [],
})
```
**Purpose**: Creates a new damage report in Firestore
**Returns**: Document ID of the created report
**Usage**: Call when a user submits a new damage report

#### 2. Get Single Damage Report
```dart
Future<Map<String, dynamic>?> getDamageReport(String reportId)
```
**Purpose**: Retrieves a specific damage report by ID
**Returns**: Report data as Map or null if not found

#### 3. Get User's Damage Reports
```dart
Future<List<Map<String, dynamic>>> getDamageReportsForUser(String userId)
```
**Purpose**: Fetches all damage reports for a specific user
**Returns**: List of user's damage reports

#### 4. Get All Pending Damage Reports
```dart
Future<List<Map<String, dynamic>>> getAllPendingDamageReports()
```
**Purpose**: Retrieves all damage reports with 'pending' status
**Returns**: List of pending damage reports (for professionals to browse)

#### 5. Update Damage Report
```dart
Future<void> updateDamageReport(String reportId, Map<String, dynamic> updates)
```
**Purpose**: Updates specific fields of a damage report
**Usage**: Modify report details, status, etc.

#### 6. Update Damage Report Status
```dart
Future<void> updateDamageReportStatus(String reportId, String status)
```
**Purpose**: Updates only the status field of a damage report
**Usage**: Change status from 'pending' to 'in_progress', 'completed', etc.

#### 7. Delete Damage Report
```dart
Future<void> deleteDamageReport(String reportId)
```
**Purpose**: Permanently removes a damage report
**Usage**: Clean up old or invalid reports

#### 8. Batch Save Multiple Reports
```dart
Future<void> saveMultipleDamageReports(List<Map<String, dynamic>> reports)
```
**Purpose**: Saves multiple damage reports in a single batch operation
**Usage**: Bulk import or migration of reports

#### 9. Search Damage Reports
```dart
Future<List<Map<String, dynamic>>> searchDamageReports({
  String? ownerId,
  String? status,
  String? vehicleMake,
  String? vehicleModel,
  int? minYear,
  int? maxYear,
  double? minCost,
  double? maxCost,
})
```
**Purpose**: Advanced search with multiple criteria
**Usage**: Filter reports by various parameters

### Estimate Operations

#### 1. Create Estimate
```dart
Future<String> createEstimate({
  required String reportId,
  required String ownerId,
  required String professionalId,
  required String professionalEmail,
  String? professionalBio,
  required double cost,
  required int leadTimeDays,
  required String description,
  List<String> imageUrls = const [],
})
```
**Purpose**: Creates a new estimate for a damage report
**Returns**: Document ID of the created estimate

#### 2. Get Estimates for Report
```dart
Future<List<Map<String, dynamic>>> getEstimatesForReport(String reportId)
```
**Purpose**: Retrieves all estimates for a specific damage report
**Returns**: List of estimates for the report

#### 3. Get Estimates for User
```dart
Future<List<Map<String, dynamic>>> getEstimatesForUser(String userId)
```
**Purpose**: Fetches all estimates where user is owner or professional
**Returns**: Combined list of user's estimates

#### 4. Update Estimate Status
```dart
Future<void> updateEstimateStatus(String estimateId, String status)
```
**Purpose**: Updates estimate status (pending/accepted/declined)
**Usage**: When owner accepts or declines an estimate

#### 5. Delete Estimate
```dart
Future<void> deleteEstimate(String estimateId)
```
**Purpose**: Removes an estimate from the system
**Usage**: Clean up invalid or withdrawn estimates

### Real-time Listeners

#### 1. Damage Reports Stream
```dart
Stream<QuerySnapshot> getDamageReportsStream(String ownerId)
```
**Purpose**: Real-time updates for user's damage reports

#### 2. Available Jobs Stream
```dart
Stream<QuerySnapshot> getAvailableJobsStream()
```
**Purpose**: Real-time updates for pending damage reports (professionals)

#### 3. Estimates Stream
```dart
Stream<QuerySnapshot> getEstimatesStream(String professionalId)
```
**Purpose**: Real-time updates for professional's estimates

## 🎯 AppState Methods

### Firestore Integration

#### 1. Load User's Damage Reports
```dart
Future<void> loadDamageReportsFromFirestore(String userId)
```
**Purpose**: Loads user's damage reports from Firestore into local state

#### 2. Load Pending Damage Reports
```dart
Future<void> loadPendingDamageReportsFromFirestore()
```
**Purpose**: Loads all pending damage reports (for professionals)

#### 3. Search in Firestore
```dart
Future<void> searchDamageReportsInFirestore({
  String? ownerId,
  String? status,
  String? vehicleMake,
  String? vehicleModel,
  int? minYear,
  int? maxYear,
  double? minCost,
  double? maxCost,
})
```
**Purpose**: Searches damage reports in Firestore with criteria

#### 4. Sync with Firestore
```dart
Future<void> syncWithFirestore(String userId)
```
**Purpose**: Synchronizes local state with Firestore data

#### 5. Load Estimates for Report
```dart
Future<void> loadEstimatesForReport(String reportId)
```
**Purpose**: Loads all estimates for a specific damage report

#### 6. Update Status in Firestore
```dart
Future<void> updateDamageReportStatusInFirestore(String reportId, String status)
Future<void> updateEstimateStatusInFirestore(String estimateId, String status)
```
**Purpose**: Updates status in both Firestore and local state

## 🧪 Testing Methods

### Available Test Buttons (Repair Professional Dashboard)

1. **Test Firestore Connection** - Verifies basic connectivity
2. **Create Test Estimate** - Creates a sample estimate
3. **Create Test Damage Report** - Creates a sample damage report
4. **Load Pending Damage Reports** - Fetches all pending reports

## 📊 Data Structure

### Damage Report Document
```json
{
  "id": "auto_generated",
  "ownerId": "user_id",
  "vehicleMake": "Toyota",
  "vehicleModel": "Camry",
  "vehicleYear": 2020,
  "damageDescription": "Front bumper damage",
  "imageUrls": ["url1", "url2"],
  "estimatedCost": 5000.0,
  "additionalNotes": "Additional details",
  "status": "pending",
  "timestamp": "server_timestamp",
  "createdAt": "server_timestamp",
  "updatedAt": "server_timestamp"
}
```

### Estimate Document
```json
{
  "id": "auto_generated",
  "reportId": "damage_report_id",
  "ownerId": "user_id",
  "professionalId": "professional_user_id",
  "professionalEmail": "pro@example.com",
  "professionalBio": "Professional bio",
  "cost": 4500.0,
  "leadTimeDays": 7,
  "description": "Repair description",
  "imageUrls": ["url1", "url2"],
  "status": "pending",
  "submittedAt": "server_timestamp",
  "updatedAt": "server_timestamp",
  "acceptedAt": null,
  "declinedAt": null
}
```

## 🚀 Usage Examples

### Creating a Damage Report
```dart
final firestoreService = FirebaseFirestoreService();
final reportId = await firestoreService.createDamageReport(
  ownerId: 'user123',
  vehicleMake: 'Honda',
  vehicleModel: 'Civic',
  vehicleYear: 2019,
  damageDescription: 'Rear-end collision damage',
  image: selectedImage,
  estimatedCost: 3000.0,
  additionalNotes: 'Insurance claim in progress',
);
```

### Loading User's Reports
```dart
final appState = context.read<AppState>();
await appState.loadDamageReportsFromFirestore('user123');
```

### Searching Reports
```dart
final firestoreService = FirebaseFirestoreService();
final results = await firestoreService.searchDamageReports(
  status: 'pending',
  vehicleMake: 'Toyota',
  minYear: 2018,
  maxCost: 10000.0,
);
```

## 🔒 Security Rules

Your Firestore security rules are already configured to allow:
- Users to read/write their own profiles
- Authenticated users to read all damage reports
- Report owners to write to their own reports
- All authenticated users to create estimates
- Professionals to update their own estimates

## 📱 Integration Points

These methods integrate with:
- **Owner Dashboard**: Create and manage damage reports
- **Professional Dashboard**: Browse available jobs and submit estimates
- **Settings Screen**: User profile management
- **Real-time Updates**: Live data synchronization across devices

## 🎉 Benefits

1. **Persistent Storage**: All data saved to Firestore
2. **Real-time Sync**: Live updates across devices
3. **Offline Support**: Local caching with sync capabilities
4. **Scalable**: Handles multiple users and large datasets
5. **Secure**: Role-based access control
6. **Searchable**: Advanced filtering and search capabilities

Your app now has full Firestore integration for both damage reports and estimates!
