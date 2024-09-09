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

.PHONY: all clean build_ta_lib

all:
	@echo "Please use 'make build_ta_lib VERSION=X.X.X' to build TA-Lib XCFramework"

build_ta_lib:
ifndef VERSION
	$(error VERSION is not set. Use 'make build_ta_lib VERSION=X.X.X')
endif
	@echo "Building TA-Lib version $(VERSION)"
	@$(MAKE) _build_ta_lib VERSION=$(VERSION)

_build_ta_lib: $(TA_LIB_DIR)
	# Build for iphoneos (arm64)
	$(call build_for_ios,arm64,arm-apple-darwin)
	
	# Build for iphonesimulator (arm64)
	$(call build_for_ios_simulator,arm64,arm-apple-darwin)
	
	# Build for iphonesimulator (x86_64)
	$(call build_for_ios_simulator,x86_64,x86_64-apple-darwin)
	
	# Build for macOS (arm64)
	$(call build_for_macos,arm64,arm-apple-darwin)
	
	# Build for macOS (x86_64)
	$(call build_for_macos,x86_64,x86_64-apple-darwin)
	
	# Build for watchOS (arm64)
	$(call build_for_watchos,arm64,arm-apple-darwin)
	
	# Build for watchOS (arm64_32)
	$(call build_for_watchos,arm64_32,arm-apple-darwin)
	
	# Build for watchOS (armv7k)
	$(call build_for_watchos,armv7k,arm-apple-darwin)
	
	# Build for watchOS simulator (arm64)
	$(call build_for_watchos_simulator,arm64,arm-apple-darwin)
	
	# Build for watchOS simulator (x86_64)
	$(call build_for_watchos_simulator,x86_64,x86_64-apple-darwin)

	# Build for tvOS (arm64)
	$(call build_for_tvos,arm64,arm-apple-darwin)
	
	# Build for tvOS simulator (arm64)
	$(call build_for_tvos_simulator,arm64,arm-apple-darwin)
	
	# Build for tvOS simulator (x86_64)
	$(call build_for_tvos_simulator,x86_64,x86_64-apple-darwin)

	# Build for visionOS (arm64)
	$(call build_for_visionos,arm64,arm-apple-darwin)
	
	# Build for visionOS simulator (arm64)
	$(call build_for_visionos_simulator,arm64,arm-apple-darwin)
	
	@$(MAKE) _create_xcframework

	-rm -r $(TA_LIB_DIR)

define build_for_ios
	SDK=$(DEVELOPER)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk; \
	export CC=$(TOOLCHAIN)/usr/bin/clang; \
	export CFLAGS="-arch $(1) -isysroot $$SDK -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET) $(OPTIMIZATION_FLAGS)"; \
	export LDFLAGS="-arch $(1) -isysroot $$SDK"; \
	(cd $(TA_LIB_DIR) && \
	./configure --host=$(2) --prefix=$(CURDIR)/$(TA_LIB_DIR)/install_iphoneos_$(1) --enable-static --disable-shared && \
	make clean && \
	make && \
	make install)
endef

define build_for_ios_simulator
	SDK=$(DEVELOPER)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk; \
	export CC=$(TOOLCHAIN)/usr/bin/clang; \
	export CFLAGS="-arch $(1) -isysroot $$SDK -mios-simulator-version-min=$(IPHONEOS_DEPLOYMENT_TARGET) -target $(1)-apple-ios-simulator $(OPTIMIZATION_FLAGS)"; \
	export LDFLAGS="-arch $(1) -isysroot $$SDK -target $(1)-apple-ios-simulator"; \
	(cd $(TA_LIB_DIR) && \
	./configure --host=$(2) --prefix=$(CURDIR)/$(TA_LIB_DIR)/install_iphonesimulator_$(1) --enable-static --disable-shared && \
	make clean && \
	make && \
	make install)
endef

define build_for_macos
	SDK=$(DEVELOPER)/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk; \
	export CC=$(TOOLCHAIN)/usr/bin/clang; \
	export CFLAGS="-arch $(1) -isysroot $$SDK -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET) $(OPTIMIZATION_FLAGS)"; \
	export LDFLAGS="-arch $(1) -isysroot $$SDK"; \
	(cd $(TA_LIB_DIR) && \
	./configure --host=$(2) --prefix=$(CURDIR)/$(TA_LIB_DIR)/install_macosx_$(1) --enable-static --disable-shared && \
	make clean && \
	make && \
	make install)
endef

define build_for_watchos
	SDK=$(DEVELOPER)/Platforms/WatchOS.platform/Developer/SDKs/WatchOS.sdk; \
	export CC=$(TOOLCHAIN)/usr/bin/clang; \
	export CFLAGS="-arch $(1) -isysroot $$SDK -mwatchos-version-min=$(WATCHOS_DEPLOYMENT_TARGET) $(OPTIMIZATION_FLAGS)"; \
	export LDFLAGS="-arch $(1) -isysroot $$SDK"; \
	(cd $(TA_LIB_DIR) && \
	./configure --host=$(2) --prefix=$(CURDIR)/$(TA_LIB_DIR)/install_watchos_$(1) --enable-static --disable-shared && \
	make clean && \
	make && \
	make install)
endef

define build_for_watchos_simulator
	SDK=$(DEVELOPER)/Platforms/WatchSimulator.platform/Developer/SDKs/WatchSimulator.sdk; \
	export CC=$(TOOLCHAIN)/usr/bin/clang; \
	export CFLAGS="-arch $(1) -isysroot $$SDK -mwatchos-simulator-version-min=$(WATCHOS_DEPLOYMENT_TARGET) -target $(1)-apple-watchos-simulator $(OPTIMIZATION_FLAGS)"; \
	export LDFLAGS="-arch $(1) -isysroot $$SDK -target $(1)-apple-watchos-simulator"; \
	(cd $(TA_LIB_DIR) && \
	./configure --host=$(2) --prefix=$(CURDIR)/$(TA_LIB_DIR)/install_watchsimulator_$(1) --enable-static --disable-shared && \
	make clean && \
	make && \
	make install)
endef

define build_for_tvos
	SDK=$(DEVELOPER)/Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS.sdk; \
	export CC=$(TOOLCHAIN)/usr/bin/clang; \
	export CFLAGS="-arch $(1) -isysroot $$SDK -mtvos-version-min=$(TVOS_DEPLOYMENT_TARGET) $(OPTIMIZATION_FLAGS)"; \
	export LDFLAGS="-arch $(1) -isysroot $$SDK"; \
	(cd $(TA_LIB_DIR) && \
	./configure --host=$(2) --prefix=$(CURDIR)/$(TA_LIB_DIR)/install_tvos_$(1) --enable-static --disable-shared && \
	make clean && \
	make && \
	make install)
endef

define build_for_tvos_simulator
	SDK=$(DEVELOPER)/Platforms/AppleTVSimulator.platform/Developer/SDKs/AppleTVSimulator.sdk; \
	export CC=$(TOOLCHAIN)/usr/bin/clang; \
	export CFLAGS="-arch $(1) -isysroot $$SDK -mtvos-simulator-version-min=$(TVOS_DEPLOYMENT_TARGET) -target $(1)-apple-tvos-simulator $(OPTIMIZATION_FLAGS)"; \
	export LDFLAGS="-arch $(1) -isysroot $$SDK -target $(1)-apple-tvos-simulator"; \
	(cd $(TA_LIB_DIR) && \
	./configure --host=$(2) --prefix=$(CURDIR)/$(TA_LIB_DIR)/install_tvossimulator_$(1) --enable-static --disable-shared && \
	make clean && \
	make && \
	make install)
endef

define build_for_visionos
	SDK=$(DEVELOPER)/Platforms/XROS.platform/Developer/SDKs/XROS.sdk; \
	export CC=$(TOOLCHAIN)/usr/bin/clang; \
	export CFLAGS="-arch $(1) -isysroot $$SDK -target $(1)-apple-xros$(VISIONOS_DEPLOYMENT_TARGET) $(OPTIMIZATION_FLAGS)"; \
	export LDFLAGS=""; \
	(cd $(TA_LIB_DIR) && \
	./configure --host=$(2) --prefix=$(CURDIR)/$(TA_LIB_DIR)/install_visionos_$(1) --enable-static --disable-shared && \
	make clean && \
	make && \
	make install)
endef

define build_for_visionos_simulator
	SDK=$(DEVELOPER)/Platforms/XRSimulator.platform/Developer/SDKs/XRSimulator.sdk; \
	export CC=$(TOOLCHAIN)/usr/bin/clang; \
	export CFLAGS="-arch $(1) -isysroot $$SDK -target $(1)-apple-xros$(VISIONOS_DEPLOYMENT_TARGET)-simulator $(OPTIMIZATION_FLAGS)"; \
	export LDFLAGS=""; \
	(cd $(TA_LIB_DIR) && \
	./configure --host=$(2) --prefix=$(CURDIR)/$(TA_LIB_DIR)/install_visionossimulator_$(1) --enable-static --disable-shared && \
	make clean && \
	make && \
	make install)
endef

_create_xcframework:
	# Create necessary directories
	mkdir -p $(TA_LIB_DIR)/install_iphonesimulator_universal/lib
	mkdir -p $(TA_LIB_DIR)/install_macosx_universal/lib
	mkdir -p $(TA_LIB_DIR)/install_watchos_universal/lib
	mkdir -p $(TA_LIB_DIR)/install_watchsimulator_universal/lib
	mkdir -p $(TA_LIB_DIR)/install_tvossimulator_universal/lib
	
	# Combine simulator architectures into a fat library
	lipo -create \
		$(TA_LIB_DIR)/install_iphonesimulator_arm64/lib/libta_lib.a \
		$(TA_LIB_DIR)/install_iphonesimulator_x86_64/lib/libta_lib.a \
		-output $(TA_LIB_DIR)/install_iphonesimulator_universal/lib/libta_lib.a
	
	# Combine macOS architectures into a fat library
	lipo -create \
		$(TA_LIB_DIR)/install_macosx_arm64/lib/libta_lib.a \
		$(TA_LIB_DIR)/install_macosx_x86_64/lib/libta_lib.a \
		-output $(TA_LIB_DIR)/install_macosx_universal/lib/libta_lib.a
	
	# Combine watchOS device architectures into a fat library
	lipo -create \
		$(TA_LIB_DIR)/install_watchos_arm64/lib/libta_lib.a \
		$(TA_LIB_DIR)/install_watchos_arm64_32/lib/libta_lib.a \
		$(TA_LIB_DIR)/install_watchos_armv7k/lib/libta_lib.a \
		-output $(TA_LIB_DIR)/install_watchos_universal/lib/libta_lib.a
	
	# Combine watchOS simulator architectures into a fat library
	lipo -create \
		$(TA_LIB_DIR)/install_watchsimulator_arm64/lib/libta_lib.a \
		$(TA_LIB_DIR)/install_watchsimulator_x86_64/lib/libta_lib.a \
		-output $(TA_LIB_DIR)/install_watchsimulator_universal/lib/libta_lib.a
	
	# Combine tvOS simulator architectures into a fat library
	lipo -create \
		$(TA_LIB_DIR)/install_tvossimulator_arm64/lib/libta_lib.a \
		$(TA_LIB_DIR)/install_tvossimulator_x86_64/lib/libta_lib.a \
		-output $(TA_LIB_DIR)/install_tvossimulator_universal/lib/libta_lib.a
	
	# Create the module map
	echo "module TALib {" > $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib/module.modulemap
	echo "    umbrella header \"ta_libc.h\"" >> $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib/module.modulemap
	echo "    export *" >> $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib/module.modulemap
	echo "}" >> $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib/module.modulemap

	# Create XCFramework from fat libraries for all platforms
	xcodebuild -create-xcframework \
		-library $(TA_LIB_DIR)/install_iphoneos_arm64/lib/libta_lib.a \
		-headers $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib \
		-library $(TA_LIB_DIR)/install_iphonesimulator_universal/lib/libta_lib.a \
		-headers $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib \
		-library $(TA_LIB_DIR)/install_macosx_universal/lib/libta_lib.a \
		-headers $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib \
		-library $(TA_LIB_DIR)/install_watchos_universal/lib/libta_lib.a \
		-headers $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib \
		-library $(TA_LIB_DIR)/install_watchsimulator_universal/lib/libta_lib.a \
		-headers $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib \
		-library $(TA_LIB_DIR)/install_tvos_arm64/lib/libta_lib.a \
		-headers $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib \
		-library $(TA_LIB_DIR)/install_tvossimulator_universal/lib/libta_lib.a \
		-headers $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib \
 		-library $(TA_LIB_DIR)/install_visionos_arm64/lib/libta_lib.a \
 		-headers $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib \
		-library $(TA_LIB_DIR)/install_visionossimulator_arm64/lib/libta_lib.a \
		-headers $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib \
		-output $(TA_LIB_OUTPUT_DIR)/TALib.xcframework
	@echo "XCFramework with module map created at $(TA_LIB_OUTPUT_DIR)/TALib.xcframework"

$(TA_LIB_DIR):
	curl -L https://github.com/TA-Lib/ta-lib/releases/download/v$(VERSION)/ta-lib-$(VERSION)-src.tar.gz -o ta-lib-$(VERSION)-src.tar.gz
	tar -xzf ta-lib-$(VERSION)-src.tar.gz
	-mv ta-lib $(TA_LIB_DIR)
	rm ta-lib-$(VERSION)-src.tar.gz

clean:
	rm -rf $(TA_LIB_DIR) $(TA_LIB_OUTPUT_DIR)/TALib.xcframework ta-lib*