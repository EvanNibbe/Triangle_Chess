#include "register_exporters.h"
#include "platform/android/export/export.h"
#include "platform/ios/export/export.h"
#include "platform/linuxbsd/export/export.h"
#include "platform/macos/export/export.h"
#include "platform/uwp/export/export.h"
#include "platform/web/export/export.h"
#include "platform/windows/export/export.h"
void register_exporters() {
	register_android_exporter();
	register_ios_exporter();
	register_linuxbsd_exporter();
	register_macos_exporter();
	register_uwp_exporter();
	register_web_exporter();
	register_windows_exporter();
}
