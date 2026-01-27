# iOS Encryption Compliance Configuration Session

**Date:** January 26, 2026  
**Context:** Adding encryption compliance declaration to avoid App Store submission questions

## User Prompts

1. **Initial Request:**
   > "there is no algorithme can you update info plist to avoid asking each times : Quel type d'algorithme de chiffrement votre app utilise‑t‑elle ?
   > 
   > Algorithmes de chiffrement propriétaires ou non considérés comme standard par les organismes de normalisation internationaux (IEEE, IETF, UIT, etc.)
   > 
   > Algorithmes de chiffrement standard à la place ou en complément de l'utilisation du chiffrement employé dans le système d'exploitation d'Apple ou de l'accès à ce chiffrement
   > 
   > Les deux algorithmes mentionnés ci‑dessus
   > 
   > Aucun des algorithmes mentionnés ci‑dessus"

## AI Responses & Plan

### Analysis
The user wants to avoid being asked about encryption algorithms during each App Store submission. This question appears because Apple needs to comply with export regulations regarding encryption software.

For most Flutter apps that only use standard HTTPS connections (which is the case here), the app uses **exempt encryption** (standard encryption provided by Apple's operating system). This means we can declare that the app does NOT use non-exempt encryption.

### Implementation Plan

1. **Add ITSAppUsesNonExemptEncryption key** to Info.plist
2. **Set value to false** - indicating the app only uses exempt encryption (standard HTTPS)
3. **Place it appropriately** in the Info.plist structure

## Code Changes Made

### File: `ios/Runner/Info.plist`

#### Added Encryption Compliance Declaration:
- **Added key**: `ITSAppUsesNonExemptEncryption`
- **Set value**: `<false/>` - indicates the app does NOT use non-exempt encryption
- **Meaning**: The app only uses exempt encryption (standard HTTPS via URLSession/network libraries)

#### Location:
Added after `BGTaskSchedulerPermittedIdentifiers` and before `UILaunchStoryboardName`:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>fr.jnvui.fosdemFlutter.workmanager.background</string>
</array>
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
<key>UILaunchStoryboardName</key>
```

## Decisions

1. **Value Set to False**: 
   - `false` means the app does NOT use non-exempt encryption
   - This is correct for apps that only use standard HTTPS connections
   - Standard HTTPS via URLSession, Dio, or other network libraries is considered **exempt encryption**

2. **Why This Works**:
   - HTTPS connections use standard TLS/SSL encryption provided by the OS
   - This is considered "exempt" from export documentation requirements
   - By declaring `false`, we tell Apple the app only uses exempt encryption
   - This avoids the need to answer encryption questions during submission

3. **When to Use `true`**:
   - Only if the app uses proprietary encryption algorithms
   - Only if the app implements custom encryption beyond standard OS-provided encryption
   - For this app, `false` is correct since it only uses standard HTTPS

## Export Compliance Information

### What is Exempt Encryption?
- Standard encryption provided by Apple's operating system
- HTTPS/TLS connections via standard network APIs
- Encryption used by system frameworks (URLSession, etc.)

### What is Non-Exempt Encryption?
- Proprietary encryption algorithms
- Custom encryption implementations
- Non-standard encryption methods

### For This App:
- Uses standard HTTPS for network requests (via Dio, http package)
- Uses standard encryption provided by iOS
- No custom encryption algorithms
- **Therefore**: `ITSAppUsesNonExemptEncryption = false` is correct

## Summary

Added `ITSAppUsesNonExemptEncryption` key set to `false` in Info.plist. This declares that the app only uses exempt encryption (standard HTTPS), which will prevent Apple from asking encryption compliance questions during App Store submission.

The app will now automatically pass the encryption compliance check without manual intervention during each submission.
