import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dot/core/network/dio_client.dart';
import 'package:dot/features/scan/data/scan_remote_datasource.dart';
import 'package:dot/features/scan/data/scan_repository_impl.dart';
import 'package:dot/features/scan/domain/scan_repository.dart';
import 'package:dot/features/scan/domain/scan_text_usecase.dart';

// Core Providers (Should likely be in lib/core/di but keeping here for feature isolation per rules)
final dioClientProvider = Provider((ref) => DioClient());
final supabaseClientProvider = Provider((ref) => Supabase.instance.client);

// Data
final scanRemoteDataSourceProvider = Provider((ref) {
  return ScanRemoteDataSource(
    ref.read(dioClientProvider),
    ref.read(supabaseClientProvider),
  );
});

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepositoryImpl(ref.read(scanRemoteDataSourceProvider));
});

// Domain
final scanTextUseCaseProvider = Provider((ref) {
  return ScanTextUseCase(ref.read(scanRepositoryProvider));
});
