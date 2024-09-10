TA_LIB_DIR = ta-lib
TA_LIB_OUTPUT_DIR = Sources/TALib
DEVELOPER = $(shell xcode-select -print-path)
TOOLCHAIN = $(DEVELOPER)/Toolchains/XcodeDefault.xctoolchain
IPHONEOS_DEPLOYMENT_TARGET = 12.0
MACOSX_DEPLOYMENT_TARGET = 10.13
WATCHOS_DEPLOYMENT_TARGET = 4.0
TVOS_DEPLOYMENT_TARGET = 12.0
VISIONOS_DEPLOYMENT_TARGET = 1.0

# Add optimization flags
OPTIMIZATION_FLAGS = -O3

# Check CMake version
CMAKE_VERSION := $(shell cmake --version | head -n1 | awk '{print $$3}')
CMAKE_VERSION_MAJOR := $(shell echo $(CMAKE_VERSION) | cut -d. -f1)
CMAKE_VERSION_MINOR := $(shell echo $(CMAKE_VERSION) | cut -d. -f2)
CMAKE_VERSION_PATCH := $(shell echo $(CMAKE_VERSION) | cut -d. -f3)

.PHONY: all clean build_ta_lib check_cmake_version

all:
	@echo "Please use 'make build_ta_lib' to build TA-Lib XCFramework"

build_ta_lib: check_cmake_version
	@echo "Building TA-Lib from latest source"
	@$(MAKE) _build_ta_lib

check_cmake_version:
	@if [ $(CMAKE_VERSION_MAJOR) -lt 3 ] || { [ $(CMAKE_VERSION_MAJOR) -eq 3 ] && [ $(CMAKE_VERSION_MINOR) -lt 30 ]; } || { [ $(CMAKE_VERSION_MAJOR) -eq 3 ] && [ $(CMAKE_VERSION_MINOR) -eq 30 ] && [ $(CMAKE_VERSION_PATCH) -lt 3 ]; }; then \
		echo "CMake version 3.30.3 or higher is required. Current version: $(CMAKE_VERSION)"; \
		exit 1; \
	fi

_build_ta_lib: $(TA_LIB_DIR)
	# Build for iphoneos (arm64)
	$(call build_for_platform,OS64,$(IPHONEOS_DEPLOYMENT_TARGET))
	
	# Build for iphonesimulator (arm64)
	$(call build_for_platform,SIMULATORARM64,$(IPHONEOS_DEPLOYMENT_TARGET))
	
	# Build for iphonesimulator (x86_64)
	$(call build_for_platform,SIMULATOR64,$(IPHONEOS_DEPLOYMENT_TARGET))
	
	# Build for macOS (arm64)
	$(call build_for_platform,MAC_ARM64,$(MACOSX_DEPLOYMENT_TARGET))
	
	# Build for macOS (x86_64)
	$(call build_for_platform,MAC,$(MACOSX_DEPLOYMENT_TARGET))
	
	# Build for watchOS (arm64)
	$(call build_for_platform,WATCHOS,$(WATCHOS_DEPLOYMENT_TARGET))
	
	# Build for watchOS simulator (arm64)
	$(call build_for_platform,SIMULATORARM64_WATCHOS,$(WATCHOS_DEPLOYMENT_TARGET))
	
	# Build for watchOS simulator (x86_64)
	$(call build_for_platform,SIMULATOR_WATCHOS,$(WATCHOS_DEPLOYMENT_TARGET))

	# Build for tvOS (arm64)
	$(call build_for_platform,TVOS,$(TVOS_DEPLOYMENT_TARGET))
	
	# Build for tvOS simulator (arm64)
	$(call build_for_platform,SIMULATORARM64_TVOS,$(TVOS_DEPLOYMENT_TARGET))
	
	# Build for tvOS simulator (x86_64)
	$(call build_for_platform,SIMULATOR_TVOS,$(TVOS_DEPLOYMENT_TARGET))

	# Build for visionOS (arm64)
	$(call build_for_platform,VISIONOS,$(VISIONOS_DEPLOYMENT_TARGET))
	
	# Build for visionOS simulator (arm64)
	$(call build_for_platform,SIMULATOR_VISIONOS,$(VISIONOS_DEPLOYMENT_TARGET))
	
	@$(MAKE) _create_xcframework

define build_for_platform
	@echo "Building for platform: $(1) with deployment target: $(2)"
	mkdir -p $(TA_LIB_DIR)/build_$(1)
	cmake -B $(TA_LIB_DIR)/build_$(1) \
		-DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/ios.toolchain.cmake \
		-DPLATFORM=$(1) \
		-DDEPLOYMENT_TARGET=$(2) \
		-DBUILD_SHARED_LIBS=OFF \
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
		-DCMAKE_C_FLAGS="$(OPTIMIZATION_FLAGS)" \
		-DCMAKE_CXX_FLAGS="$(OPTIMIZATION_FLAGS)" \
		$(TA_LIB_DIR)
	@echo "CMake configuration completed for $(1)"
	cmake --build $(TA_LIB_DIR)/build_$(1) --parallel $$(shell nproc) --config Release
	@echo "Build completed for $(1)"
endef

_create_xcframework:
	mkdir $(TA_LIB_DIR)/headers
	cp $(TA_LIB_DIR)/include/*.h $(TA_LIB_DIR)/headers/
	rm $(TA_LIB_DIR)/headers/ta_config.h

	# Create the module map
	echo "module TALib {" > $(TA_LIB_DIR)/headers/module.modulemap
	echo "    umbrella header \"ta_libc.h\"" >> $(TA_LIB_DIR)/headers/module.modulemap
	echo "    export *" >> $(TA_LIB_DIR)/headers/module.modulemap
	echo "}" >> $(TA_LIB_DIR)/headers/module.modulemap

	# Create necessary directories
	mkdir -p $(TA_LIB_DIR)/build_iphonesimulator_universal
	mkdir -p $(TA_LIB_DIR)/build_macosx_universal
	mkdir -p $(TA_LIB_DIR)/build_watchsimulator_universal
	mkdir -p $(TA_LIB_DIR)/build_tvossimulator_universal
	
	# Combine simulator architectures into a fat library
	lipo -create \
		$(TA_LIB_DIR)/build_SIMULATOR64/libta_lib.a \
		$(TA_LIB_DIR)/build_SIMULATORARM64/libta_lib.a \
		-output $(TA_LIB_DIR)/build_iphonesimulator_universal/libta_lib.a
	
	# Combine macOS architectures into a fat library
	lipo -create \
		$(TA_LIB_DIR)/build_MAC/libta_lib.a \
		$(TA_LIB_DIR)/build_MAC_ARM64/libta_lib.a \
		-output $(TA_LIB_DIR)/build_macosx_universal/libta_lib.a
	
	# Combine watchOS simulator architectures into a fat library
	lipo -create \
		$(TA_LIB_DIR)/build_SIMULATORARM64_WATCHOS/libta_lib.a \
		$(TA_LIB_DIR)/build_SIMULATOR_WATCHOS/libta_lib.a \
		-output $(TA_LIB_DIR)/build_watchsimulator_universal/libta_lib.a
	
	# Combine tvOS simulator architectures into a fat library
	lipo -create \
		$(TA_LIB_DIR)/build_SIMULATOR_TVOS/libta_lib.a \
		$(TA_LIB_DIR)/build_SIMULATORARM64_TVOS/libta_lib.a \
		-output $(TA_LIB_DIR)/build_tvossimulator_universal/libta_lib.a

	# Create XCFramework from fat libraries for all platforms
	xcodebuild -create-xcframework \
		-library $(TA_LIB_DIR)/build_OS64/libta_lib.a \
		-headers $(TA_LIB_DIR)/headers \
		-library $(TA_LIB_DIR)/build_iphonesimulator_universal/libta_lib.a \
		-headers $(TA_LIB_DIR)/headers \
		-library $(TA_LIB_DIR)/build_macosx_universal/libta_lib.a \
		-headers $(TA_LIB_DIR)/headers \
		-library $(TA_LIB_DIR)/build_WATCHOS/libta_lib.a \
		-headers $(TA_LIB_DIR)/headers \
		-library $(TA_LIB_DIR)/build_watchsimulator_universal/libta_lib.a \
		-headers $(TA_LIB_DIR)/headers \
		-library $(TA_LIB_DIR)/build_TVOS/libta_lib.a \
		-headers $(TA_LIB_DIR)/headers \
		-library $(TA_LIB_DIR)/build_tvossimulator_universal/libta_lib.a \
		-headers $(TA_LIB_DIR)/headers \
		-library $(TA_LIB_DIR)/build_VISIONOS/libta_lib.a \
		-headers $(TA_LIB_DIR)/headers \
		-library $(TA_LIB_DIR)/build_SIMULATOR_VISIONOS/libta_lib.a \
		-headers $(TA_LIB_DIR)/headers \
		-output $(TA_LIB_OUTPUT_DIR)/TALib.xcframework
	@echo "XCFramework created at $(TA_LIB_OUTPUT_DIR)/TALib.xcframework"

$(TA_LIB_DIR):
	git clone https://github.com/TA-Lib/ta-lib.git $(TA_LIB_DIR)

clean:
	rm -rf $(TA_LIB_DIR) $(TA_LIB_OUTPUT_DIR)/TALib.xcframework