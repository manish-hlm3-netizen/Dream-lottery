const path = require('path');
module.paths.push(path.join(__dirname, 'backend/node_modules'));

const fs = require('fs');
const { execSync } = require('child_process');
const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config({ path: path.join(__dirname, 'backend/.env') });

const MONGODB_URI = process.env.MONGODB_URI;

// Define Settings Schema
const settingsSchema = new mongoose.Schema({
  key: { type: String, required: true, unique: true, default: 'upi_settings' },
  upiId: { type: String, required: true, default: 'pay@upi' },
  qrCodeUrl: { type: String, default: '' },
  appVersion: { type: String, default: '1.0.0' },
  appDownloadUrl: { type: String, default: '' }
}, { timestamps: true });

const Settings = mongoose.models.Settings || mongoose.model('Settings', settingsSchema);

async function run() {
  try {
    // 1. Read pubspec.yaml to extract version name
    console.log('📖 Reading pubspec.yaml...');
    const pubspecPath = path.join(__dirname, 'lottery_app/pubspec.yaml');
    if (!fs.existsSync(pubspecPath)) {
      throw new Error(`pubspec.yaml not found at ${pubspecPath}`);
    }
    const pubspecContent = fs.readFileSync(pubspecPath, 'utf8');
    const versionMatch = pubspecContent.match(/^version:\s*([\d\.]+)/m);
    if (!versionMatch) {
      throw new Error('Could not find version in pubspec.yaml');
    }
    const appVersion = versionMatch[1];
    console.log(`💡 Detected App Version: ${appVersion}`);

    // Update api_config.dart automatically to prevent update loops
    console.log('📝 Synchronizing api_config.dart appVersion...');
    const apiConfigPath = path.join(__dirname, 'lottery_app/lib/config/api_config.dart');
    if (fs.existsSync(apiConfigPath)) {
      let apiConfigContent = fs.readFileSync(apiConfigPath, 'utf8');
      apiConfigContent = apiConfigContent.replace(
        /static const String appVersion = '[^']+';/,
        `static const String appVersion = '${appVersion}';`
      );
      fs.writeFileSync(apiConfigPath, apiConfigContent, 'utf8');
      console.log('✅ api_config.dart synchronized successfully.');
    } else {
      console.log('⚠️ api_config.dart not found, skipping sync.');
    }

    // 2. Build the Flutter APK release bundle
    console.log('🔨 Compiling Flutter release APK...');
    const flutterAppDir = path.join(__dirname, 'lottery_app');
    let buildCommand = 'flutter build apk --release';
    try {
      execSync('where flutter', { stdio: 'ignore' });
    } catch (e) {
      console.log('⚠️ flutter command not found in PATH, trying to locate Shorebird cache...');
      try {
        const os = require('os');
        const userHome = os.homedir();
        const shorebirdFlutterDir = path.join(userHome, '.shorebird/bin/cache/flutter');
        if (fs.existsSync(shorebirdFlutterDir)) {
          const revisions = fs.readdirSync(shorebirdFlutterDir);
          let foundPath = null;
          for (const rev of revisions) {
            const candidate = path.join(shorebirdFlutterDir, rev, 'bin/flutter.bat');
            if (fs.existsSync(candidate)) {
              foundPath = candidate;
              break;
            }
          }
          if (foundPath) {
            console.log(`✅ Found Shorebird-managed Flutter at: ${foundPath}`);
            buildCommand = `"${foundPath}" build apk --release`;
          }
        }
      } catch (err) {
        console.log('⚠️ Could not locate Shorebird-managed Flutter, defaulting to flutter...');
      }
    }
    console.log(`Running build command: ${buildCommand}`);
    execSync(buildCommand, { cwd: flutterAppDir, stdio: 'inherit' });
    console.log('✅ Flutter release APK compiled successfully.');

    // 3. Define source and destination paths
    const srcApk = path.join(flutterAppDir, 'build/app/outputs/flutter-apk/app-release.apk');
    const destApkName = `dream-lottery-${appVersion}.apk`;
    const destApk = path.join(__dirname, 'backend/public', destApkName);

    // Ensure public folder exists
    const publicDir = path.dirname(destApk);
    if (!fs.existsSync(publicDir)) {
      fs.mkdirSync(publicDir, { recursive: true });
    }

    // Remove any older app-release-*.apk or dream-lottery-*.apk files to keep the directory clean
    console.log('🧹 Cleaning older versioned APK files...');
    const files = fs.readdirSync(publicDir);
    for (const file of files) {
      if ((file.startsWith('app-release-') || file.startsWith('dream-lottery-')) && file.endsWith('.apk') && file !== destApkName) {
        fs.unlinkSync(path.join(publicDir, file));
        console.log(`   Removed: ${file}`);
      }
    }

    // 4. Copy and rename the built APK to destination
    console.log(`🚚 Copying and renaming APK to: ${destApkName}...`);
    fs.copyFileSync(srcApk, destApk);
    console.log('✅ Copy complete.');

    // 5. Connect to MongoDB and update settings
    if (MONGODB_URI) {
      console.log('🔌 Connecting to MongoDB...');
      await mongoose.connect(MONGODB_URI);
      console.log('🔌 Connected!');

      let settings = await Settings.findOne({ key: 'upi_settings' });
      if (!settings) {
        console.log('Creating new settings...');
        settings = new Settings({ key: 'upi_settings' });
      }

      settings.appVersion = appVersion;
      settings.appDownloadUrl = 'https://dream-lottery.onrender.com/api/app/download';
      await settings.save();
      console.log(`🚀 Successfully updated database OTA version to: ${appVersion}`);
      await mongoose.disconnect();
      console.log('🔌 Disconnected.');
    } else {
      console.log('⚠️ MONGODB_URI not found. Skipping database OTA update.');
    }

    console.log('\n🎉 Build and deploy pipeline finished successfully!');
  } catch (error) {
    console.error('❌ Build and Deploy Error:', error);
    process.exit(1);
  }
}

run();
