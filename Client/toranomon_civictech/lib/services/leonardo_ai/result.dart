/// 型安全なエラーハンドリングのためのResult型
/// 
/// 成功時はSuccessを、失敗時はFailureを返す
sealed class Result<T, E> {
  const Result();
  
  /// 成功結果
  const factory Result.success(T data) = Success<T, E>;
  
  /// 失敗結果
  const factory Result.failure(E error) = Failure<T, E>;
  
  /// 成功かどうかを判定
  bool get isSuccess => this is Success<T, E>;
  
  /// 失敗かどうかを判定
  bool get isFailure => this is Failure<T, E>;
}

/// 成功結果を表すクラス
class Success<T, E> extends Result<T, E> {
  final T data;
  
  const Success(this.data);
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T, E> && other.data == data;
  }
  
  @override
  int get hashCode => data.hashCode;
  
  @override
  String toString() => 'Success(data: $data)';
}

/// 失敗結果を表すクラス
class Failure<T, E> extends Result<T, E> {
  final E error;
  
  const Failure(this.error);
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure<T, E> && other.error == error;
  }
  
  @override
  int get hashCode => error.hashCode;
  
  @override
  String toString() => 'Failure(error: $error)';
}

/// Result型の拡張メソッド
extension ResultExtension<T, E> on Result<T, E> {
  /// 成功時のデータを取得（失敗時はnull）
  T? get dataOrNull {
    if (this is Success<T, E>) {
      return (this as Success<T, E>).data;
    }
    return null;
  }
  
  /// 失敗時のエラーを取得（成功時はnull）
  E? get errorOrNull {
    if (this is Failure<T, E>) {
      return (this as Failure<T, E>).error;
    }
    return null;
  }
  
  /// 成功時のデータを取得（失敗時は例外をスロー）
  T get data {
    if (this is Success<T, E>) {
      return (this as Success<T, E>).data;
    } else if (this is Failure<T, E>) {
      final error = (this as Failure<T, E>).error;
      if (error is Exception) {
        throw error;
      } else {
        throw Exception(error.toString());
      }
    }
    throw StateError('Unknown Result type');
  }
  
  /// 失敗時のエラーを取得（成功時は例外をスロー）
  E get error {
    if (this is Failure<T, E>) {
      return (this as Failure<T, E>).error;
    } else if (this is Success<T, E>) {
      final data = (this as Success<T, E>).data;
      throw StateError('Result is success with data: $data');
    }
    throw StateError('Unknown Result type');
  }
  
  /// 成功・失敗それぞれに対して処理を実行
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(E error) onFailure,
  ) {
    if (this is Success<T, E>) {
      return onSuccess((this as Success<T, E>).data);
    } else if (this is Failure<T, E>) {
      return onFailure((this as Failure<T, E>).error);
    }
    throw StateError('Unknown Result type');
  }
  
  /// 成功時に変換処理を適用
  Result<U, E> transform<U>(U Function(T) transform) {
    if (this is Success<T, E>) {
      return Result.success(transform((this as Success<T, E>).data));
    } else if (this is Failure<T, E>) {
      return Result.failure((this as Failure<T, E>).error);
    }
    throw StateError('Unknown Result type');
  }
  
  /// 失敗時に変換処理を適用
  Result<T, F> mapError<F>(F Function(E) transform) {
    if (this is Success<T, E>) {
      return Result.success((this as Success<T, E>).data);
    } else if (this is Failure<T, E>) {
      return Result.failure(transform((this as Failure<T, E>).error));
    }
    throw StateError('Unknown Result type');
  }
  
  /// 成功時に非同期変換処理を適用
  Future<Result<U, E>> mapAsync<U>(Future<U> Function(T) transform) async {
    if (this is Success<T, E>) {
      return Result.success(await transform((this as Success<T, E>).data));
    } else if (this is Failure<T, E>) {
      return Result.failure((this as Failure<T, E>).error);
    }
    throw StateError('Unknown Result type');
  }
  
  /// 成功時にResultを返す変換処理を適用（flatMap）
  Result<U, E> flatMap<U>(Result<U, E> Function(T) transform) {
    if (this is Success<T, E>) {
      return transform((this as Success<T, E>).data);
    } else if (this is Failure<T, E>) {
      return Result.failure((this as Failure<T, E>).error);
    }
    throw StateError('Unknown Result type');
  }
  
  /// 成功時に非同期でResultを返す変換処理を適用
  Future<Result<U, E>> flatMapAsync<U>(Future<Result<U, E>> Function(T) transform) async {
    if (this is Success<T, E>) {
      return await transform((this as Success<T, E>).data);
    } else if (this is Failure<T, E>) {
      return Result.failure((this as Failure<T, E>).error);
    }
    throw StateError('Unknown Result type');
  }
}