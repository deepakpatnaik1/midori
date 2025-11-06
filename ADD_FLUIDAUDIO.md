# Adding FluidAudio to Midori

## Step 1: Add Swift Package Dependency (In Xcode)

1. Open `midori.xcodeproj` in Xcode (if not already open)
2. Click on the **midori project** in the left sidebar (blue icon)
3. Select the **midori target**
4. Click the **"+"** button under "Frameworks, Libraries, and Embedded Content" section
5. Click **"Add Package Dependency"**
6. In the search field, paste: `https://github.com/FluidInference/FluidAudio.git`
7. Click **"Add Package"**
8. Select **"FluidAudio"** product and click **"Add Package"**

## Step 2: Code Changes (I'll do this automatically)

Once you've added the package, I'll update:
- `TranscriptionManager.swift` - Replace mock with real FluidAudio
- `AudioRecorder.swift` - Enable real audio recording
- Handle audio format conversion to 16kHz mono

## Quick Version (If you want to do it via command line)

Alternatively, after I prepare the code, you can:
1. Just build in Xcode
2. When it fails with "No such module 'FluidAudio'", Xcode will prompt you to resolve packages
3. Click "Resolve" and it will add it automatically

Let me know when you've added the package, or just try building and I'll help you through any errors!
