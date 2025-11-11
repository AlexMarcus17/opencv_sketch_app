import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ExportPreferenceDropdown<T> extends StatelessWidget {
  const ExportPreferenceDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.onSelected,
  });

  final String label;
  final T value;
  final List<T> values;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 38, bottom: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            child: Row(
              children: [
                Text(
                  value.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_down,
                    color: Colors.white, size: 14),
              ],
            ),
            onPressed: () async {
              final chosen = await showCupertinoModalPopup<T>(
                context: context,
                builder: (context) {
                  return CupertinoActionSheet(
                    actions: values
                        .map(
                          (v) => CupertinoActionSheetAction(
                            onPressed: () => Navigator.pop(context, v),
                            child: Text(v.toString()),
                          ),
                        )
                        .toList(),
                    cancelButton: CupertinoActionSheetAction(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  );
                },
              );
              if (chosen != null) {
                onSelected(chosen);
              }
            },
          ),
        ],
      ),
    );
  }
}
