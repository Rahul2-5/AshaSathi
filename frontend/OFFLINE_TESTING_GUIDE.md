# Offline/Online Sync Testing Guide

## Summary of Changes

### ✅ Fixed Issues

1. **Family Registration Now Offline-First**
   - Modified `submitFamilyRegistration()` in PatientService
   - Saves family data to SharedPreferences BEFORE attempting backend sync
   - If offline, data persists locally and syncs when online
   - If online sync fails, data still saved locally for later retry

2. **Individual Patient Save (Already Working)**
   - PatientOfflineService saves patients to local SQLite
   - PatientSyncService handles auto-sync when online
   - Proper pending/synced status tracking

## Testing Scenarios

### Scenario 1: OFFLINE SAVE (No Internet)

**Steps:**
1. Start the app normally
2. Ensure you're logged in
3. Navigate to "Add Patient" section
4. **Disable internet on emulator:**
   - Open emulator settings
   - Look for Network/WiFi settings
   - Disable WiFi and Mobile Data
   - OR open Android Settings > Airplane Mode OFF > WiFi OFF
5. Fill in patient form with test data:
   - Name: "Test Patient Offline"
   - Age: 25
   - DOB: 1999-01-15
   - Gender: Female
   - Address: "Test Address"
   - Phone: "1234567890"
   - Select a photo
6. Click Save
7. **Expected Result:**
   - App should show "Patient saved offline" or similar message
   - Patient should appear in the list
   - No error message about server connection

**Log Indicators:**
```
✅ Family saved to offline storage
💾 Database operation successful
📝 Mark as pending for sync
```

### Scenario 2: ONLINE SAVE (Internet Connected)

**Steps:**
1. Ensure internet is enabled on emulator
2. Backend server is running and accessible
3. Navigate to "Add Patient" section
4. Fill in patient form:
   - Name: "Test Patient Online"
   - Age: 30
   - DOB: 1994-06-20
   - Different address and phone
   - Select photo
5. Click Save
6. **Expected Result:**
   - Shows "Patient saved successfully" or "Patient registered online"
   - Patient appears in list immediately
   - Server responds successfully
   - No pending sync messages

**Log Indicators:**
```
🟢 Online: Submitting to server
✅ Created patient serverId=X
📸 Photo uploaded successfully
☑️ Mark as synced
```

### Scenario 3: OFFLINE-TO-ONLINE SYNC (Delayed Sync)

**Steps:**
1. **Go offline** (disable WiFi on emulator)
2. Add 2-3 patients while offline:
   - Fill patient form
   - Click Save
   - Verify "saved offline" message
   - Each patient should appear in list
3. **Reconnect to internet:**
   - Open emulator settings
   - Enable WiFi/Mobile Data
   - Verify backend is reachable
4. **Trigger sync:**
   - Navigate to Home page or Patient list
   - App should automatically start syncing
   - OR open menu and press "Sync" if available
5. **Expected Result:**
   - Offline patients gradually disappear from pending
   - Server IDs assigned to patients
   - Patients now show as "synced"
   - No error messages during sync

**Log Indicators:**
```
[PatientSync] checking connectivity...
[PatientSync] starting sync
[PatientSync] pending patients: 3
[PatientSync] created patient serverId=55
[PatientSync] created patient serverId=56
[PatientSync] created patient serverId=57
[PatientSync] finished sync
```

### Scenario 4: CONFLICT DETECTION (Optional)

**Steps:**
1. While offline, edit an existing patient
2. Go online without syncing edits
3. Edit same patient on another device/backend
4. Trigger sync
5. **Expected Result:**
   - App detects conflict
   - Shows conflict resolution UI
   - User can choose local or server version

## Checking Results

### Local Database Inspection

**For Patients:**
- Location: SQLite database in app data
- Table: `patients`
- Check: `syncStatus` field
  - `pending` = waiting to sync
  - `synced` = already on server
  - `deleted` = marked for deletion
  - `conflict` = conflicting versions

### SharedPreferences (Family Data)

**For Family Registration:**
- Key: `pending_family_*`
- Value: JSON payload of family + patients
- When empty: All families synced successfully

### App Logs

Monitor these log patterns:
```
[PatientSync] → Patient sync operations
[TaskSync] → Task sync operations  
Offline mode: → Offline operations
🔴 Offline: → Working with local data
🟢 Online: → Syncing with server
✅ Created → Successful creation
```

## Expected Timeline

| Phase | Time | What Happens |
|-------|------|--------------|
| Offline Save | Immediate | Data saved locally |
| Online Attempts | 30-60 sec | Auto-sync triggered |
| Sync Started | ~5 sec | Loading server index |
| Create on Server | Per patient | Usually <2 sec each |
| Photo Upload | 2-5 sec | Per photo |
| Sync Complete | Total 15-30 sec | All pending synced |

## Commands for Testing

### Kill and Restart App
```bash
adb shell am force-stop com.ashasathi.frontend
adb shell am start -n com.ashasathi.frontend/.MainActivity
```

### Force Sync
- Currently happens automatically on app load
- Can trigger by returning to home page

### Clear Database (Full Reset)
```bash
# This would require code changes to add a "Clear All" button
# For now, uninstall and reinstall the app
adb uninstall com.ashasathi.frontend
```

## Common Issues & Fixes

### Issue: "Offline" when should be online
**Fix:** Check backend is running and reachable
```bash
curl http://192.168.1.x:8080/health
```

### Issue: Sync never starts
**Fix:** Navigate back to home page or close/reopen app
- Sync triggers on app resume

### Issue: Photos not uploading
**Fix:** Ensure photo path is correct and file exists
- Check SharedPreferences for photoPath field

### Issue: Family data lost
**Fix:** New offline-first implementation should prevent this
- Check pending_family_* keys in SharedPreferences
- Manual restoration from SharedPreferences if needed

## Success Criteria

✅ All three scenarios complete without errors
✅ Offline data persists correctly
✅ Auto-sync doesn't duplicate records
✅ Photos upload and display correctly
✅ Conflict detection works if tested
✅ No data loss during offline periods
✅ Clean transition from offline to online
