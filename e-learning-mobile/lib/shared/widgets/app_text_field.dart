import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.fieldKey,
    this.controller,
    this.focusNode,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
  });

  final Key? fieldKey;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final errMessage = errorText;
    final hasError = errMessage != null && errMessage.isNotEmpty;

    final label = labelText;
    final prefix = prefixIcon;
    final suffix = suffixIcon;

    final borderColor = hasError
        ? colorScheme.error
        : const Color(0xFFE9EBEA);
    final fillColor = enabled
        ? (theme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerHigh
            : const Color(0xFFF4F6F5))
        : colorScheme.surface.withValues(alpha: 0.5);
    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: enabled
          ? const Color(0xFF1E2621)
          : const Color(0xFF1E2621).withValues(alpha: 0.38),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: borderColor,
              width: hasError ? 1.5 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              if (prefix != null) ...[
                IconTheme(
                  data: const IconThemeData(
                    color: Color(0xFF717873),
                    size: 20,
                  ),
                  child: prefix,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: DefaultTextStyle(
                  style: textStyle,
                  child: TextField(
                    key: fieldKey,
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    autofillHints: autofillHints,
                    inputFormatters: inputFormatters,
                    enabled: enabled,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    cursorColor: colorScheme.primary,
                    style: textStyle,
                    decoration: InputDecoration(
                      filled: false,
                      fillColor: Colors.transparent,
                      hintText: hintText,
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFFA5A9A5),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 8),
                IconTheme(
                  data: const IconThemeData(
                    color: Color(0xFF717873),
                    size: 20,
                  ),
                  child: suffix,
                ),
              ],
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              errMessage,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.error,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ],
    );
  }
}




