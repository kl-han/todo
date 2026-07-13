/// Typed REST client for the Quadrant Todo API.
///
/// The presentation layer talks to backends exclusively through this
/// package, regardless of whether the backend is the embedded loopback
/// server or a remote standalone server.
library;

export 'src/client/quadrant_api_client.dart';
export 'src/dto/capabilities.dart';
export 'src/dto/health_report.dart';
export 'src/dto/recurrence_dto.dart';
export 'src/dto/tag_dto.dart';
export 'src/dto/task_dto.dart';
export 'src/errors/api_exception.dart';
