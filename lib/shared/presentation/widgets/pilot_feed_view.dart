import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/evaluation/pilot_events.dart';
import '../../../core/evaluation/pilot_feed.dart';
import '../../../core/evaluation/pilot_visibility.dart';
import '../../../features/catalog/data/product_model.dart';
import '../../../features/wholesale/presentation/wholesale_pages.dart';

class PilotFeedView extends StatelessWidget {
  const PilotFeedView({super.key, required this.lists, this.season});
  final List<PilotFeedList> lists;
  final PilotSeasonContext? season;
  static const retailTitle = String.fromEnvironment(
    'PILOT_RETAIL_TITLE',
    defaultValue: 'Productores cerca de ti',
  );
  static const wholesaleTitle = String.fromEnvironment(
    'PILOT_WHOLESALE_TITLE',
    defaultValue: 'Organizaciones de productores',
  );
  static const retailSubtitle = String.fromEnvironment(
    'PILOT_RETAIL_SUBTITLE',
    defaultValue: 'Pedidos pequeños, entrega local',
  );
  static const wholesaleSubtitle = String.fromEnvironment(
    'PILOT_WHOLESALE_SUBTITLE',
    defaultValue: 'Compra por volumen, con cotización',
  );

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[if (season != null) _seasonBanner(season!)];
    String? previous;
    for (final list in lists) {
      if (previous != list.segment) {
        previous = list.segment;
        final wholesale = list.segment == 'WHOLESALE';
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wholesale ? wholesaleTitle : retailTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(wholesale ? wholesaleSubtitle : retailSubtitle),
              ],
            ),
          ),
        );
      }
      widgets.add(_carousel(context, list));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _seasonBanner(PilotSeasonContext context) {
    final month = context.monthName.isEmpty
        ? ''
        : '${context.monthName[0].toUpperCase()}${context.monthName.substring(1)}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EF),
        border: Border.all(color: const Color(0xFFB8D9C8)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, color: Color(0xFF26705A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temporada agrícola de $month',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Disponibilidad verificada al ${context.date.day}/${context.date.month}/${context.date.year}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carousel(BuildContext context, PilotFeedList list) {
    // Both sections share exactly the same card and typography.
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            list.section == 'RECOMMENDED'
                ? 'Recomendados para ti'
                : 'Populares',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (list.items.isEmpty)
            const Text('No hay productos disponibles en tu zona.')
          else
            PilotVisibility(
              identity: 'list-${list.id}',
              onViewed: () => PilotEventsQueue.instance.record(
                'LIST_VIEWED',
                listId: list.id,
                sessionId: list.sessionId,
              ),
              child: SizedBox(
                height: 290 + (textScale - 1).clamp(0, 3) * 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: list.items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _card(context, list, list.items[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    PilotFeedList list,
    Map<String, dynamic> item,
  ) {
    final raw = Map<String, dynamic>.from(item['product'] as Map);
    final id = item['productId'] as String;
    final wholesale = list.segment == 'WHOLESALE';
    final retail = wholesale
        ? null
        : Producto.fromJson({...raw, 'id': id}).copiarCon(
            sourceSection: list.section,
            sourcePosition: (item['rank'] as num).toInt(),
            recommendationRequestId: list.id,
          );
    final name = wholesale ? raw['name']?.toString() ?? '' : retail!.nombre;
    final image = wholesale
        ? raw['imageUrl']?.toString() ?? ''
        : retail!.urlImagen;
    void open() {
      unawaited(
        PilotEventsQueue.instance.record(
          'CLICK',
          listId: list.id,
          productId: id,
          sessionId: list.sessionId,
        ),
      );
      if (wholesale) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WholesaleQuoteRequestPage(
              initialProduct: {
                ...raw,
                'id': id,
                'originListId': list.id,
                'originSessionId': list.sessionId,
              },
            ),
          ),
        );
      } else {
        Navigator.pushNamed(context, '/detalle_producto', arguments: retail);
      }
    }

    return PilotVisibility(
      identity: 'item-${list.id}-$id',
      onViewed: () => PilotEventsQueue.instance.record(
        'ITEM_IMPRESSION',
        listId: list.id,
        productId: id,
        sessionId: list.sessionId,
      ),
      child: SizedBox(
        width: 235,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            onTap: open,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 115,
                  width: double.infinity,
                  child: image.isEmpty
                      ? const Icon(Icons.image_outlined)
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.image_outlined),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          wholesale
                              ? raw['organizationName']?.toString() ?? ''
                              : retail!.nombreVendedor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          wholesale
                              ? 'S/ ${raw['referencePrice']} / ${raw['unit']}'
                              : 'S/ ${retail!.precio.toStringAsFixed(2)} / ${retail.unidad}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: open,
                            child: Text(
                              wholesale ? 'Agregar a cotización' : 'Agregar',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
