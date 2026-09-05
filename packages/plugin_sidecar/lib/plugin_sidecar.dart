/// Desktop sidecar plugin framework.
///
/// Provides safe package installation, framed JSON-RPC communication and
/// process supervision for desktop sidecar plugins. UI-free by design;
/// hosts render declarative results themselves.
library;

export 'src/package/install_state_machine.dart';
export 'src/package/io_file_system.dart';
export 'src/package/package_builder.dart';
export 'src/package/package_paths.dart';
export 'src/package/package_reader.dart';
export 'src/package/sidecar_installer.dart';
export 'src/process/io_process_launcher.dart';
export 'src/process/sidecar_process.dart';
export 'src/process/sidecar_supervisor.dart';
export 'src/process/stdio_rpc_transport.dart';
export 'src/rpc/rpc_channel.dart';
export 'src/rpc/rpc_frame_codec.dart';
export 'src/rpc/rpc_message_codec.dart';
export 'src/session/sidecar_session.dart';
