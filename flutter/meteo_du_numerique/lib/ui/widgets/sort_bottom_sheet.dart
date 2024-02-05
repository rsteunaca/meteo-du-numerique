import 'package:flutter/material.dart';

import '../../bloc/items_bloc/items_bloc.dart';
import '../../bloc/items_bloc/items_event.dart';

class SortBottomSheet extends StatefulWidget {
  final ItemsBloc itemsBloc;
  final String? selectedSorting;
  final String? selectedOrder;

  const SortBottomSheet(
      {super.key, required this.itemsBloc, required this.selectedSorting, required this.selectedOrder});

  @override
  State<SortBottomSheet> createState() => _SortBottomSheetState();
}

class _SortBottomSheetState extends State<SortBottomSheet> {
  String? _selectedSortCriteria;
  String? _selectedSortOrder;

  @override
  void initState() {
    super.initState();
    _selectedSortCriteria = widget.selectedSorting!;
    _selectedSortOrder = widget.selectedOrder!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 50.0, top: 20.0, left: 10, right: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RadioListTile<String>(
            title: const Text('État décroissant'),
            value: 'qualiteDeServiceId_desc',
            groupValue: '${_selectedSortCriteria!}_${_selectedSortOrder ?? ''}',
            onChanged: (String? value) {
              _onSortChanged('qualiteDeServiceId', 'desc');
            },
          ),
          RadioListTile<String>(
            title: const Text('État croissant'),
            value: 'qualiteDeServiceId_asc',
            groupValue: '${_selectedSortCriteria!}_${_selectedSortOrder ?? ''}',
            onChanged: (String? value) {
              _onSortChanged('qualiteDeServiceId', 'asc');
            },
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 10.0, bottom: 10.0),
            child: Divider(),
          ),
          RadioListTile<String>(
            title: const Text('Nom du service (A-Z)'),
            value: 'libelle_asc',
            groupValue: '${_selectedSortCriteria!}_${_selectedSortOrder ?? ''}',
            onChanged: (String? value) {
              _onSortChanged('libelle', 'asc');
            },
          ),
          RadioListTile<String>(
            title: const Text('Nom du service (Z-A)'),
            value: 'libelle_desc',
            groupValue: '${_selectedSortCriteria!}_${_selectedSortOrder ?? ''}',
            onChanged: (String? value) {
              _onSortChanged('libelle', 'desc');
            },
          ),
        ],
      ),
    );
  }

  void _onSortChanged(String criteria, String order) {
    setState(() {
      _selectedSortCriteria = criteria;
      _selectedSortOrder = order;
    });

    widget.itemsBloc.add(SortItemsEvent(criteria, order));
    Navigator.pop(context);
  }
}
