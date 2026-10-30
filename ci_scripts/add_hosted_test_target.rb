#!/usr/bin/env ruby
# Adds an ActifitHostedTests unit-test target that runs inside the Actifit app (TEST_HOST), for
# code that needs the app's pods, such as on-device Hive signing (secp256k1), plus a shared
# scheme to run it. Uses the `xcodeproj` gem that ships with CocoaPods, so project.pbxproj is
# never hand-edited:
#   ruby ci_scripts/add_hosted_test_target.rb
#   xcodebuild test -workspace Actifit.xcworkspace -scheme ActifitHostedTests \
#     -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

require "xcodeproj"

PROJECT_PATH = "Actifit.xcodeproj"
TARGET_NAME  = "ActifitHostedTests"
APP_TARGET   = "Actifit"
TEST_FILES   = ["ActifitHostedTests/HiveCryptoTests.swift"]
# Compiled into the test bundle directly (only `import secp256k1` is needed), so the tests don't
# have to import the app module and, with it, every pod's private modules.
APP_SOURCES  = ["Actifit/Hive/HiveTx.swift", "Actifit/Hive/HiveCrypto.swift"]

project = Xcodeproj::Project.open(PROJECT_PATH)
app = project.targets.find { |t| t.name == APP_TARGET } or raise "App target '#{APP_TARGET}' not found"
target = project.targets.find { |t| t.name == TARGET_NAME }

if target
  puts "Target #{TARGET_NAME} already exists — skipping creation"
else
  target = project.new_target(:unit_test_bundle, TARGET_NAME, :ios, "15.0", nil, :swift)
  group = project.main_group.find_subpath(TARGET_NAME, true)
  group.set_source_tree("SOURCE_ROOT")
  group.set_path(TARGET_NAME)
  refs = TEST_FILES.map { |f| group.new_reference(File.basename(f)) }
  APP_SOURCES.each do |path|
    refs << (project.files.find { |f| f.path == path } or raise "#{path} is not in the project")
  end
  target.add_file_references(refs)

  target.build_configurations.each do |config|
    bs = config.build_settings
    bs["PRODUCT_BUNDLE_IDENTIFIER"] = "com.Actifit.fitnesstracker.hostedtests"
    bs["PRODUCT_NAME"] = "$(TARGET_NAME)"
    bs["SWIFT_VERSION"] = "5.0"
    bs["IPHONEOS_DEPLOYMENT_TARGET"] = "15.0"
    bs["GENERATE_INFOPLIST_FILE"] = "YES"
    bs["CODE_SIGNING_ALLOWED"] = "NO"
    bs["CODE_SIGN_IDENTITY"] = ""
    bs["TARGETED_DEVICE_FAMILY"] = "1,2"
    # Runs inside the app, which embeds the pod frameworks (secp256k1) the test bundle links.
    bs["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/Actifit.app/Actifit"
    bs["BUNDLE_LOADER"] = "$(TEST_HOST)"
    # The app's CocoaPods settings, so `import secp256k1` resolves and links (what a Podfile
    # `inherit! :search_paths` would give, without naming this on-demand target there).
    app_config = app.build_configurations.find { |c| c.name == config.name }
    config.base_configuration_reference = app_config.base_configuration_reference if app_config
  end
  target.add_dependency(app)
  project.save
  puts "Created target #{TARGET_NAME}"
end

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(target)
scheme.set_launch_target(app)
scheme.save_as(PROJECT_PATH, TARGET_NAME, true)
puts "Saved shared scheme #{TARGET_NAME}"
