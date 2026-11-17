// Mocks for WindowAdapter used across window_service_test,
// windows_window_service_test, window_resize_strategy_test,
// window_interaction_strategy_test, and strip_controller_test.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;
import 'dart:ui' as _i2;

import 'package:happening/core/window/window_adapter.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class
// ignore_for_file: invalid_use_of_internal_member

class _FakeSize_0 extends _i1.SmartFake implements _i2.Size {
  _FakeSize_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeOffset_1 extends _i1.SmartFake implements _i2.Offset {
  _FakeOffset_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [WindowAdapter].
class MockWindowManager extends _i1.Mock implements _i3.WindowAdapter {
  @override
  double getDevicePixelRatio() => (super.noSuchMethod(
        Invocation.method(
          #getDevicePixelRatio,
          [],
        ),
        returnValue: 0.0,
        returnValueForMissingStub: 0.0,
      ) as double);

  @override
  _i4.Future<void> configureInitialWindow({
    required _i2.Size? size,
    required _i2.Color? backgroundColor,
    required bool? alwaysOnTop,
    required bool? skipTaskbar,
    required bool? hideTitleBar,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #configureInitialWindow,
          [],
          {
            #size: size,
            #backgroundColor: backgroundColor,
            #alwaysOnTop: alwaysOnTop,
            #skipTaskbar: skipTaskbar,
            #hideTitleBar: hideTitleBar,
          },
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> setAsFrameless() => (super.noSuchMethod(
        Invocation.method(
          #setAsFrameless,
          [],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> setBackgroundColor(_i2.Color? color) => (super.noSuchMethod(
        Invocation.method(
          #setBackgroundColor,
          [color],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> setResizable(bool? isResizable) => (super.noSuchMethod(
        Invocation.method(
          #setResizable,
          [isResizable],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> setMinimumSize(_i2.Size? size) => (super.noSuchMethod(
        Invocation.method(
          #setMinimumSize,
          [size],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> setMaximumSize(_i2.Size? size) => (super.noSuchMethod(
        Invocation.method(
          #setMaximumSize,
          [size],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> setSize(
    _i2.Size? size, {
    bool? animate = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #setSize,
          [size],
          {#animate: animate},
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<_i2.Size> getSize() => (super.noSuchMethod(
        Invocation.method(
          #getSize,
          [],
        ),
        returnValue: _i4.Future<_i2.Size>.value(_FakeSize_0(
          this,
          Invocation.method(
            #getSize,
            [],
          ),
        )),
        returnValueForMissingStub: _i4.Future<_i2.Size>.value(_FakeSize_0(
          this,
          Invocation.method(
            #getSize,
            [],
          ),
        )),
      ) as _i4.Future<_i2.Size>);

  @override
  _i4.Future<void> setPosition(
    _i2.Offset? position, {
    bool? animate = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #setPosition,
          [position],
          {#animate: animate},
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<_i2.Offset> getPosition() => (super.noSuchMethod(
        Invocation.method(
          #getPosition,
          [],
        ),
        returnValue: _i4.Future<_i2.Offset>.value(_FakeOffset_1(
          this,
          Invocation.method(
            #getPosition,
            [],
          ),
        )),
        returnValueForMissingStub: _i4.Future<_i2.Offset>.value(_FakeOffset_1(
          this,
          Invocation.method(
            #getPosition,
            [],
          ),
        )),
      ) as _i4.Future<_i2.Offset>);

  @override
  _i4.Future<void> setAlwaysOnTop(bool? isAlwaysOnTop) => (super.noSuchMethod(
        Invocation.method(
          #setAlwaysOnTop,
          [isAlwaysOnTop],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> setAlwaysOnBottom(bool? isAlwaysOnBottom) =>
      (super.noSuchMethod(
        Invocation.method(
          #setAlwaysOnBottom,
          [isAlwaysOnBottom],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> setHasShadow(bool? hasShadow) => (super.noSuchMethod(
        Invocation.method(
          #setHasShadow,
          [hasShadow],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> show({bool? inactive = false}) => (super.noSuchMethod(
        Invocation.method(
          #show,
          [],
          {#inactive: inactive},
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> focus() => (super.noSuchMethod(
        Invocation.method(
          #focus,
          [],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);

  @override
  _i4.Future<void> blur() => (super.noSuchMethod(
        Invocation.method(
          #blur,
          [],
        ),
        returnValue: _i4.Future<void>.value(),
        returnValueForMissingStub: _i4.Future<void>.value(),
      ) as _i4.Future<void>);
}
