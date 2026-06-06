#!/usr/bin/env ruby
# Adds an ActifitUITests UI-testing target to Actifit.xcodeproj and registers it
# in the shared Actifit scheme's test action. Run on CI (uses the `xcodeproj` gem
# that ships with CocoaPods) so we never hand-edit project.pbxproj.

require "xcodeproj"

PROJECT_PATH = "Actifit.xcodeproj"
TARGET_NAME  = "ActifitUITests"
APP_TARGET   = "Actifit"
TEST_FILE    = "ActifitUITests/LoginUITest.swift"

project = Xcodeproj::Project.open(PROJECT_PATH)
app = project.targets.find { |t| t.name == APP_TARGET }
raise "App target '#{APP_TARGET}' not found" unless app

test_target = project.targets.find { |t| t.name == TARGET_NAME }

if test_target
  puts "Target #{TARGET_NAME} already exists — skipping creation"
else
  test_target = project.new_target(:ui_test_bundle, TARGET_NAME, :ios, "15.0", nil, :swift)

  group = project.main_group.find_subpath(TARGET_NAME, true)
  group.set_source_tree("SOURCE_ROOT")
  group.set_path(TARGET_NAME)
  file_ref = group.new_reference(File.basename(TEST_FILE))
  test_target.add_file_references([file_ref])

  test_target.build_configurations.each do |config|
    bs = config.build_settings
    bs["TEST_TARGET_NAME"] = APP_TARGET
    bs["PRODUCT_BUNDLE_IDENTIFIER"] = "com.Actifit.fitnesstracker.uitests"
    bs["PRODUCT_NAME"] = "$(TARGET_NAME)"
    bs["SWIFT_VERSION"] = "5.0"
    bs["IPHONEOS_DEPLOYMENT_TARGET"] = "15.0"
    bs["GENERATE_INFOPLIST_FILE"] = "YES"
    bs["CODE_SIGNING_ALLOWED"] = "NO"
    bs["CODE_SIGN_IDENTITY"] = ""
    bs["TARGETED_DEVICE_FAMILY"] = "1,2"
  end

  test_target.add_dependency(app)
  project.save
  puts "Created target #{TARGET_NAME}"
end

# Register the test target in the shared Actifit scheme's test action.
scheme_path = File.join(PROJECT_PATH, "xcshareddata", "xcschemes", "#{APP_TARGET}.xcscheme")
scheme = Xcodeproj::XCScheme.new(scheme_path)
already = scheme.test_action.testables.any? do |t|
  t.buildable_references.any? { |b| b.target_name == TARGET_NAME }
end

if already
  puts "Scheme already references #{TARGET_NAME}"
else
  scheme.test_action.add_testable(Xcodeproj::XCScheme::TestAction::TestableReference.new(test_target))
  scheme.save!
  puts "Added #{TARGET_NAME} to scheme test action"
end
