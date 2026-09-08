#!/usr/bin/env bash
# Script to create Xcode project for MazeScreensaver

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"
mkdir -p MazeScreensaver.xcodeproj

# Generate UUIDs for the project
TARGET_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
SOURCE_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
MODEL_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
PLAYBACK_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
SETTINGS_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
RENDERER_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
PLIST_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
PBX_BUILD_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
MODEL_BUILD_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
PLAYBACK_BUILD_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
SETTINGS_BUILD_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
RENDERER_BUILD_FILE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
PBX_SOURCES_BUILD_PHASE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
PBX_FRAMEWORKS_BUILD_PHASE_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
PBX_NATIVE_TARGET_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
PBX_PROJECT_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
PBX_GROUP_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
PBX_ROOT_GROUP_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
PROJECT_DEBUG_CONFIG_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
PROJECT_RELEASE_CONFIG_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
TARGET_DEBUG_CONFIG_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
TARGET_RELEASE_CONFIG_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
PROJECT_CONFIG_LIST_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')
TARGET_CONFIG_LIST_UUID=$(uuidgen | tr '[:lower:]' '[:upper:]')

cat > MazeScreensaver.xcodeproj/project.pbxproj <<EOF
// !\$*UTF8*\$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		${PBX_BUILD_FILE_UUID} /* MazeScreensaverView.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${SOURCE_FILE_UUID} /* MazeScreensaverView.swift */; };
		${MODEL_BUILD_FILE_UUID} /* MazeModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${MODEL_FILE_UUID} /* MazeModel.swift */; };
		${PLAYBACK_BUILD_FILE_UUID} /* MazePlayback.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${PLAYBACK_FILE_UUID} /* MazePlayback.swift */; };
		${SETTINGS_BUILD_FILE_UUID} /* MazeSettings.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${SETTINGS_FILE_UUID} /* MazeSettings.swift */; };
		${RENDERER_BUILD_FILE_UUID} /* MazeRenderer.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${RENDERER_FILE_UUID} /* MazeRenderer.swift */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		${PLIST_FILE_UUID} /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
		${SOURCE_FILE_UUID} /* MazeScreensaverView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MazeScreensaverView.swift; sourceTree = "<group>"; };
		${MODEL_FILE_UUID} /* MazeModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MazeModel.swift; sourceTree = "<group>"; };
		${PLAYBACK_FILE_UUID} /* MazePlayback.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MazePlayback.swift; sourceTree = "<group>"; };
		${SETTINGS_FILE_UUID} /* MazeSettings.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MazeSettings.swift; sourceTree = "<group>"; };
		${RENDERER_FILE_UUID} /* MazeRenderer.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MazeRenderer.swift; sourceTree = "<group>"; };
		${TARGET_UUID} /* MazeScreensaver.saver */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = MazeScreensaver.saver; sourceTree = BUILT_PRODUCTS_DIR; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		${PBX_FRAMEWORKS_BUILD_PHASE_UUID} /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		${PBX_GROUP_UUID} /* MazeScreensaver */ = {
			isa = PBXGroup;
			children = (
				${SOURCE_FILE_UUID} /* MazeScreensaverView.swift */,
				${MODEL_FILE_UUID} /* MazeModel.swift */,
				${PLAYBACK_FILE_UUID} /* MazePlayback.swift */,
				${SETTINGS_FILE_UUID} /* MazeSettings.swift */,
				${RENDERER_FILE_UUID} /* MazeRenderer.swift */,
				${PLIST_FILE_UUID} /* Info.plist */,
			);
			path = MazeScreensaver;
			sourceTree = "<group>";
		};
		${PBX_ROOT_GROUP_UUID} = {
			isa = PBXGroup;
			children = (
				${PBX_GROUP_UUID} /* MazeScreensaver */,
			);
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		${PBX_NATIVE_TARGET_UUID} /* MazeScreensaver */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = ${TARGET_CONFIG_LIST_UUID} /* Build configuration list for PBXNativeTarget "MazeScreensaver" */;
			buildPhases = (
				${PBX_SOURCES_BUILD_PHASE_UUID} /* Sources */,
				${PBX_FRAMEWORKS_BUILD_PHASE_UUID} /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = MazeScreensaver;
			productName = MazeScreensaver;
			productReference = ${TARGET_UUID} /* MazeScreensaver.saver */;
			productType = "com.apple.product-type.bundle";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		${PBX_PROJECT_UUID} /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1620;
				LastUpgradeCheck = 1620;
			};
			buildConfigurationList = ${PROJECT_CONFIG_LIST_UUID} /* Build configuration list for PBXProject "MazeScreensaver" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = ${PBX_ROOT_GROUP_UUID};
			productRefGroup = ${PBX_ROOT_GROUP_UUID} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				${PBX_NATIVE_TARGET_UUID} /* MazeScreensaver */,
			);
		};
/* End PBXProject section */

/* Begin PBXSourcesBuildPhase section */
		${PBX_SOURCES_BUILD_PHASE_UUID} /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				${PBX_BUILD_FILE_UUID} /* MazeScreensaverView.swift in Sources */,
				${MODEL_BUILD_FILE_UUID} /* MazeModel.swift in Sources */,
				${PLAYBACK_BUILD_FILE_UUID} /* MazePlayback.swift in Sources */,
				${SETTINGS_BUILD_FILE_UUID} /* MazeSettings.swift in Sources */,
				${RENDERER_BUILD_FILE_UUID} /* MazeRenderer.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		${PROJECT_DEBUG_CONFIG_UUID} /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_APPICON_NAME = "";
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CHECK = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"\$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		${PROJECT_RELEASE_CONFIG_UUID} /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_APPICON_NAME = "";
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CHECK = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			};
			name = Release;
		};
		${TARGET_DEBUG_CONFIG_UUID} /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 14;
				DEVELOPMENT_TEAM = "";
				INFOPLIST_FILE = MazeScreensaver/Info.plist;
				INFOPLIST_KEY_NSHumanReadableCopyright = "";
				LD_RUNPATH_SEARCH_PATHS = (
					"\$(inherited)",
					"@executable_path/../Frameworks",
					"@loader_path/../Frameworks",
				);
				MARKETING_VERSION = 1.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.tido.MazeScreensaver;
				PRODUCT_MODULE_NAME = MazeScreensaver;
				PRODUCT_NAME = "\$(TARGET_NAME)";
				SDKROOT = macosx;
				SKIP_INSTALL = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				WRAPPER_EXTENSION = saver;
			};
			name = Debug;
		};
		${TARGET_RELEASE_CONFIG_UUID} /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 14;
				DEVELOPMENT_TEAM = "";
				INFOPLIST_FILE = MazeScreensaver/Info.plist;
				INFOPLIST_KEY_NSHumanReadableCopyright = "";
				LD_RUNPATH_SEARCH_PATHS = (
					"\$(inherited)",
					"@executable_path/../Frameworks",
					"@loader_path/../Frameworks",
				);
				MARKETING_VERSION = 1.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.tido.MazeScreensaver;
				PRODUCT_MODULE_NAME = MazeScreensaver;
				PRODUCT_NAME = "\$(TARGET_NAME)";
				SDKROOT = macosx;
				SKIP_INSTALL = YES;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				WRAPPER_EXTENSION = saver;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		${TARGET_CONFIG_LIST_UUID} /* Build configuration list for PBXNativeTarget "MazeScreensaver" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				${TARGET_DEBUG_CONFIG_UUID} /* Debug */,
				${TARGET_RELEASE_CONFIG_UUID} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		${PROJECT_CONFIG_LIST_UUID} /* Build configuration list for PBXProject "MazeScreensaver" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				${PROJECT_DEBUG_CONFIG_UUID} /* Debug */,
				${PROJECT_RELEASE_CONFIG_UUID} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = ${PBX_PROJECT_UUID} /* Project object */;
}
EOF

echo "Created Xcode project: MazeScreensaver.xcodeproj"

