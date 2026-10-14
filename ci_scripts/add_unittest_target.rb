#!/usr/bin/env ruby
# Adds an ActifitTests logic-test target (no host app, so no Pods) to Actifit.xcodeproj and a
# shared ActifitTests scheme to run it. It compiles the Foundation-only Arena and Friends
# sources directly.
# Run before testing (uses the `xcodeproj` gem that ships with CocoaPods), so we never
# hand-edit project.pbxproj:
#   ruby ci_scripts/add_unittest_target.rb
#   xcodebuild test -project Actifit.xcodeproj -scheme ActifitTests -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

require "xcodeproj"

PROJECT_PATH = "Actifit.xcodeproj"
TARGET_NAME  = "ActifitTests"
TEST_FILES   = ["ActifitTests/ArenaLogicTests.swift", "ActifitTests/FriendsLogicTests.swift"]
APP_SOURCES  = [
  "Actifit/Controllers/Arena/ArenaLogic.swift",
  "Actifit/Controllers/Arena/ArenaModels.swift",
  "Actifit/Controllers/Arena/ArenaText.swift",
  "Actifit/Controllers/Friends/FriendsLogic.swift"
]

project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.find { |t| t.name == TARGET_NAME }

if target
  puts "Target #{TARGET_NAME} already exists — skipping creation"
else
  target = project.new_target(:unit_test_bundle, TARGET_NAME, :ios, "15.0", nil, :swift)

  group = project.main_group.find_subpath(TARGET_NAME, true)
  group.set_source_tree("SOURCE_ROOT")
  refs = TEST_FILES.map { |f| group.new_reference(File.basename(f)) }
  group.set_path(TARGET_NAME)
  # Reuse the app's existing file references so the sources are not listed twice.
  APP_SOURCES.each do |path|
    ref = project.files.find { |f| f.path == path } or raise "#{path} is not in the project"
    refs << ref
  end
  target.add_file_references(refs)

  target.build_configurations.each do |config|
    bs = config.build_settings
    bs["PRODUCT_BUNDLE_IDENTIFIER"] = "com.Actifit.fitnesstracker.tests"
    bs["PRODUCT_NAME"] = "$(TARGET_NAME)"
    bs["SWIFT_VERSION"] = "5.0"
    bs["IPHONEOS_DEPLOYMENT_TARGET"] = "15.0"
    bs["GENERATE_INFOPLIST_FILE"] = "YES"
    bs["CODE_SIGNING_ALLOWED"] = "NO"
    bs["CODE_SIGN_IDENTITY"] = ""
    bs["TARGETED_DEVICE_FAMILY"] = "1,2"
  end
  project.save
  puts "Created target #{TARGET_NAME}"
end

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.add_test_target(target)
scheme.save_as(PROJECT_PATH, TARGET_NAME, true)
puts "Saved shared scheme #{TARGET_NAME}"
