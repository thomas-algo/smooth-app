import 'package:flutter/material.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:smooth_app/generic_lib/design_constants.dart';
import 'package:smooth_app/query/product_query.dart';
import 'package:flutter_svg/svg.dart';

/// Simple input text field, with autocompletion.
class SimpleInputTextField extends StatelessWidget {
  const SimpleInputTextField({
    required this.focusNode,
    required this.autocompleteKey,
    required this.constraints,
    required this.tagType,
    required this.hintText,
    required this.controller,
    this.withClearButton = false,
    this.minLengthForSuggestions = 1,
    this.categories,
    this.shapeProvider,
  });

  final FocusNode focusNode;
  final Key autocompleteKey;
  final BoxConstraints constraints;
  final TagType? tagType;
  final String hintText;
  final TextEditingController controller;
  final bool withClearButton;
  final int minLengthForSuggestions;
  final String? categories;
  final String? Function()? shapeProvider;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: LARGE_SPACE),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: RawAutocomplete<String>(
                key: autocompleteKey,
                focusNode: focusNode,
                textEditingController: controller,
                optionsBuilder: (final TextEditingValue value) async {
                  if (tagType == null) {
                    return <String>[];
                  }

                  final String input = value.text.trim();
                  if (input.length < minLengthForSuggestions) {
                    return <String>[];
                  }

                  return OpenFoodAPIClient.getSuggestions(
                    tagType!,
                    language: ProductQuery.getLanguage()!,
                    country: ProductQuery.getCountry(),
                    categories: categories,
                    shape: shapeProvider?.call(),
                    user: ProductQuery.getUser(),
                    limit:
                        15, // number of suggestions the user can scroll through: compromise between quantity and readability of the suggestions
                    input: input,
                  );
                },
                fieldViewBuilder: (BuildContext context,
                        TextEditingController textEditingController,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted) =>
                    TextField(
                  controller: textEditingController,
                  decoration: InputDecoration(
                    filled: true,
                    border: const OutlineInputBorder(
                      borderRadius: ANGULAR_BORDER_RADIUS,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: SMALL_SPACE,
                      vertical: SMALL_SPACE,
                    ),
                    hintText: hintText,
                  ),
                  // a lot of confusion if set to `true`
                  autofocus: false,
                  focusNode: focusNode,
                ),
                optionsViewBuilder: (
                  BuildContext lContext,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options,
                ) {
                  return AutocompleteOptionsWithIcon(
                    options: options,
                    onSelected: onSelected,
                    fieldIcon: SvgPicture.network(
                      'https://raw.githubusercontent.com/openfoodfacts/openfoodfacts-server/f2bf8d101835db4ef51049260465ec545adec374/html/images/lang/en/packaging/01-pet.73x90.svg',
                      color: Theme.of(context).colorScheme.primary,
                    ), // Color matches light/dark theme
                  );
                },
              ),
            ),
            if (withClearButton)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => controller.text = '',
              ),
          ],
        ),
      );
}

/// Allows to unfocus TextField (and dismiss the keyboard) when user tap outside the TextField and inside this widget.
/// Therefore, this widget should be put before the Scaffold to make the TextField unfocus when tapping anywhere.
class UnfocusWhenTapOutside extends StatelessWidget {
  const UnfocusWhenTapOutside({Key? key, required this.child})
      : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final FocusScopeNode currentFocus = FocusScope.of(context);

        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: child,
    );
  }
}

class AutocompleteOptionsWithIcon extends StatelessWidget {
  const AutocompleteOptionsWithIcon(
      {Key? key,
      required this.options,
      required this.onSelected,
      this.fieldIcon})
      : super(key: key);

  final Iterable<String> options;
  final AutocompleteOnSelected<String> onSelected;
  final Widget? fieldIcon; // Widget used for an icon on the right.

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        child: ConstrainedBox(
          // BoxConstraints used to let the autocomplete shrink if the number of suggestions is small
          constraints: BoxConstraints(
              maxWidth: 0.75 * MediaQuery.of(context).size.width,
              maxHeight: 0.4 * MediaQuery.of(context).size.height),

          child: ListView.separated(
            shrinkWrap:
                true, // to let the autocomplete shrink if the number of suggestions is small
            padding: EdgeInsets.zero,
            itemBuilder: (BuildContext context, int index) {
              final String option = options.elementAt(index);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                child: ListTile(
                  visualDensity: const VisualDensity(vertical: -4),
                  dense: false,
                  title: Text(option),
                  leading: fieldIcon,
                  onTap: () {
                    onSelected(option);
                  },
                ),
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(
                    height: 0), // THe margin is defined above ListTile
            itemCount: options.length,
          ),
        ),
      ),
    );
  }
}
