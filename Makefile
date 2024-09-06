TA_LIB_DIR = ta-lib
TA_LIB_OUTPUT_DIR = Sources/TALib
DEVELOPER = $(shell xcode-select -print-path)
TOOLCHAIN = $(DEVELOPER)/Toolchains/XcodeDefault.xctoolchain
IOS_SDK_VERSION = $(shell xcrun -sdk iphoneos --show-sdk-version)
MACOS_SDK_VERSION = $(shell xcrun -sdk macosx --show-sdk-version)
IPHONEOS_DEPLOYMENT_TARGET = 12.0
MACOSX_DEPLOYMENT_TARGET = 10.13

.PHONY: all clean build_ta_lib

all:
	@echo "Please use 'make build_ta_lib VERSION=X.X.X' to build TA-Lib XCFramework"

build_ta_lib:
ifndef VERSION
	$(error VERSION is not set. Use 'make build_ta_lib VERSION=X.X.X')
endif
	@echo "Building TA-Lib version $(VERSION)"
	@$(MAKE) *build*ta_lib VERSION=$(VERSION)

*build*ta_lib: $(TA_LIB_DIR)
	# Build for iphoneos (arm64)
	$(call build_for_device,arm64,iphoneos,arm-apple-darwin)
	
	# Build for iphonesimulator (arm64)
	$(call build_for_simulator,arm64,iphonesimulator,arm-apple-darwin)
	
	# Build for iphonesimulator (x86_64)
	$(call build_for_simulator,x86_64,iphonesimulator,x86_64-apple-darwin)
	
	# Build for macOS (arm64)
	$(call build_for_macos,arm64,macosx,arm-apple-darwin)
	
	# Build for macOS (x86_64)
	$(call build_for_macos,x86_64,macosx,x86_64-apple-darwin)
	
	@$(MAKE) _create_xcframework

	-rm -r $(TA_LIB_DIR)

define build_for_device
	SDK=$(DEVELOPER)/Platforms/$(2).platform/Developer/SDKs/$(2)$(IOS_SDK_VERSION).sdk; \
	export CC=$(TOOLCHAIN)/usr/bin/clang; \
	export CFLAGS="-arch $(1) -isysroot $$SDK -miphoneos-version-min=$(IPHONEOS_DEPLOYMENT_TARGET)"; \
	export LDFLAGS="-arch $(1) -isysroot $$SDK"; \
	(cd $(TA_LIB_DIR) && \
	./configure --host=$(3) --prefix=$(CURDIR)/$(TA_LIB_DIR)/install_$(2)_$(1) --enable-static --disable-shared && \
	make clean && \
	make && \
	make install)
endef

define build_for_simulator
	SDK=$(DEVELOPER)/Platforms/$(2).platform/Developer/SDKs/$(2)$(IOS_SDK_VERSION).sdk; \
	export CC=$(TOOLCHAIN)/usr/bin/clang; \
	export CFLAGS="-arch $(1) -isysroot $$SDK -mios-simulator-version-min=$(IPHONEOS_DEPLOYMENT_TARGET) -target $(1)-apple-ios-simulator"; \
	export LDFLAGS="-arch $(1) -isysroot $$SDK -target $(1)-apple-ios-simulator"; \
	(cd $(TA_LIB_DIR) && \
	./configure --host=$(3) --prefix=$(CURDIR)/$(TA_LIB_DIR)/install_$(2)_$(1) --enable-static --disable-shared && \
	make clean && \
	make && \
	make install)
endef

define build_for_macos
	SDK=$(DEVELOPER)/Platforms/$(2).platform/Developer/SDKs/$(2)$(MACOS_SDK_VERSION).sdk; \
	export CC=$(TOOLCHAIN)/usr/bin/clang; \
	export CFLAGS="-arch $(1) -isysroot $$SDK -mmacosx-version-min=$(MACOSX_DEPLOYMENT_TARGET)"; \
	export LDFLAGS="-arch $(1) -isysroot $$SDK"; \
	(cd $(TA_LIB_DIR) && \
	./configure --host=$(3) --prefix=$(CURDIR)/$(TA_LIB_DIR)/install_$(2)_$(1) --enable-static --disable-shared && \
	make clean && \
	make && \
	make install)
endef

_create_xcframework:
	# Create necessary directories
	mkdir -p $(TA_LIB_DIR)/install_iphonesimulator_universal/lib
	mkdir -p $(TA_LIB_DIR)/install_macosx_universal/lib
	
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
	
	# Create the module map
	echo "module TALib {" > $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib/module.modulemap
	echo "    umbrella header \"ta_libc.h\"" >> $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib/module.modulemap
	echo "    export *" >> $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib/module.modulemap
	echo "}" >> $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib/module.modulemap

	# Create XCFramework from fat libraries for the simulator, device, and macOS
	xcodebuild -create-xcframework \
		-library $(TA_LIB_DIR)/install_iphoneos_arm64/lib/libta_lib.a \
		-headers $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib \
		-library $(TA_LIB_DIR)/install_iphonesimulator_universal/lib/libta_lib.a \
		-headers $(TA_LIB_DIR)/install_iphoneos_arm64/include/ta-lib \
		-library $(TA_LIB_DIR)/install_macosx_universal/lib/libta_lib.a \
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