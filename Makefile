all: dependencies xcodeproj-httpservermock templates

# The release version of `dd-sdk-swift-testing` to use for tests instrumentation.
DD_SDK_SWIFT_TESTING_VERSION = 0.7.0

define DD_SDK_TESTING_XCCONFIG_CI
FRAMEWORK_SEARCH_PATHS=$$(inherited) $$(SRCROOT)/../instrumented-tests/DatadogSDKTesting.xcframework/ios-arm64_x86_64-simulator/\n
LD_RUNPATH_SEARCH_PATHS=$$(inherited) $$(SRCROOT)/../instrumented-tests/DatadogSDKTesting.xcframework/ios-arm64_x86_64-simulator/\n
OTHER_LDFLAGS=$$(inherited) -framework DatadogSDKTesting\n
DD_TEST_RUNNER=1\n
DD_SDK_SWIFT_TESTING_SERVICE=dd-sdk-ios\n
DD_SDK_SWIFT_TESTING_CLIENT_TOKEN=${DD_SDK_SWIFT_TESTING_CLIENT_TOKEN}\n
DD_SDK_SWIFT_TESTING_ENV=ci\n
endef
export DD_SDK_TESTING_XCCONFIG_CI

define DD_SDK_BASE_XCCONFIG
// Active compilation conditions - only enabled on local machine:\n
// - DD_SDK_ENABLE_INTERNAL_MONITORING - enables Internal Monitoring APIs\n
// - DD_SDK_ENABLE_EXPERIMENTAL_APIS - enables APIs which are not available in released version of the SDK\n
// - DD_SDK_COMPILED_FOR_TESTING - conditions the SDK code compiled for testing\n
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DD_SDK_ENABLE_INTERNAL_MONITORING DD_SDK_ENABLE_EXPERIMENTAL_APIS DD_SDK_COMPILED_FOR_TESTING\n
\n
// To build only active architecture for all configurations.\n
// TODO: RUMM-1200 We can perhaps remove this fix when carthage supports pre-build xcframeworks.\n
//		 The only "problematic" dependency is `CrashReporter.xcframework` which doesn't produce\n
//		 the `arm64-simulator` architecture when compiled from source. Its pre-build `CrashReporter.xcframework`\n
//		 available since `1.8.0` contains the `ios-arm64_i386_x86_64-simulator` slice and should link fine in all configurations.\n
ONLY_ACTIVE_ARCH = YES
endef
export DD_SDK_BASE_XCCONFIG

# Installs tools and dependencies with homebrew.
# Do not call 'brew update' and instead let Bitrise use its own brew bottle mirror.
dependencies:
		@./tools/crash-reporting-patch/enable-crash-reporting.sh
		@echo "⚙️  Installing dependencies..."
		@brew list swiftlint &>/dev/null || brew install swiftlint
		@brew upgrade carthage
		@carthage bootstrap --platform iOS --use-xcframeworks
		@echo $$DD_SDK_BASE_XCCONFIG > xcconfigs/Base.local.xcconfig;
ifeq (${ci}, true)
		@echo $$DD_SDK_TESTING_XCCONFIG_CI > xcconfigs/DatadogSDKTesting.local.xcconfig;
		@brew list gh &>/dev/null || brew install gh
		@rm -rf instrumented-tests/DatadogSDKTesting.xcframework
		@rm -rf instrumented-tests/DatadogSDKTesting.zip
		@rm -rf instrumented-tests/LICENSE
		@gh release download ${DD_SDK_SWIFT_TESTING_VERSION} -D instrumented-tests -R https://github.com/DataDog/dd-sdk-swift-testing -p "DatadogSDKTesting.zip"
		@unzip -q instrumented-tests/DatadogSDKTesting.zip -d instrumented-tests
		@[ -e "instrumented-tests/DatadogSDKTesting.xcframework" ] && echo "DatadogSDKTesting.xcframework - OK" || { echo "DatadogSDKTesting.xcframework - missing"; exit 1; }
endif

xcodeproj-httpservermock:
		@echo "⚙️  Generating 'HTTPServerMock.xcodeproj'..."
		@cd instrumented-tests/http-server-mock/ && swift package generate-xcodeproj
		@echo "OK 👌"

templates:
		@echo "⚙️  Installing Xcode templates..."
		./tools/xcode-templates/install-xcode-templates.sh
		@echo "OK 👌"

# Tests if current branch ships a valid SPM package.
test-spm:
		@cd dependency-manager-tests/spm && $(MAKE)

# Tests if current branch ships a valid Carthage project.
test-carthage:
		@cd dependency-manager-tests/carthage && $(MAKE)

# Tests if current branch ships a valid Cocoapods project.
test-cocoapods:
		@cd dependency-manager-tests/cocoapods && $(MAKE)

# Generate RUM data models from rum-events-format JSON Schemas
rum-models-generate:
		@echo "⚙️  Generating RUM models..."
		./tools/rum-models-generator/run.sh generate
		@echo "OK 👌"

# Verify if RUM data models follow rum-events-format JSON Schemas
rum-models-verify:
		@echo "🧪  Verifying RUM models..."
		./tools/rum-models-generator/run.sh verify
		@echo "OK 👌"

# Generate api-surface files for Datadog and DatadogObjc.
api-surface:
		@cd tools/api-surface/ && swift build --configuration release
		@echo "Generating api-surface-swift"
		./tools/api-surface/.build/x86_64-apple-macosx/release/api-surface workspace --workspace-name Datadog.xcworkspace --scheme Datadog --path . > api-surface-swift
		@echo "Generating api-surface-objc"
		./tools/api-surface/.build/x86_64-apple-macosx/release/api-surface workspace --workspace-name Datadog.xcworkspace --scheme DatadogObjc --path . > api-surface-objc

bump:
		@read -p "Enter version number: " version;  \
		echo "// GENERATED FILE: Do not edit directly\n\ninternal let sdkVersion = \"$$version\"" > Sources/Datadog/Versioning.swift; \
		sed "s/__DATADOG_VERSION__/$$version/g" DatadogSDK.podspec.src > DatadogSDK.podspec; \
		sed "s/__DATADOG_VERSION__/$$version/g" DatadogSDKObjc.podspec.src > DatadogSDKObjc.podspec; \
		sed "s/__DATADOG_VERSION__/$$version/g" DatadogSDKAlamofireExtension.podspec.src > DatadogSDKAlamofireExtension.podspec; \
		git add . ; \
		git commit -m "Bumped version to $$version"; \
		echo Bumped version to $$version

ship:
		pod spec lint --allow-warnings DatadogSDK.podspec
		pod trunk push --allow-warnings --synchronous DatadogSDK.podspec
		pod repo update
		./tools/standalone-binary-distro/make_distro_builds.sh
		@echo "⚠️ DatadogSDKObjc.podspec needs to be tried after ~1 hour:"
		@echo "pod spec lint --allow-warnings DatadogSDKObjc.podspec"
		@echo "pod trunk push --allow-warnings DatadogSDKObjc.podspec"

dogfood:
		@cd tools/dogfooding && $(MAKE)
