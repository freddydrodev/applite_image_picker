import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
// import 'package:appliteui_client/utils/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

enum AppliteImagePickerDeleteMode { asset, url }

class AppliteImagePickerImageUrl {
  final String url;
  final String providerId;

  AppliteImagePickerImageUrl({required this.url, required this.providerId});
}

class AppliteImagePickerOnChangeResult {
  final List<File> assets;
  final List<AppliteImagePickerImageUrl> imagesUrls;
  final List<AppliteImagePickerImageUrl> removedImagesUrls;

  const AppliteImagePickerOnChangeResult({
    required this.assets,
    required this.imagesUrls,
    required this.removedImagesUrls,
  });
}

class MultiImagePicker extends StatefulWidget {
  final List<AppliteImagePickerImageUrl> initImages;
  final dynamic Function(AppliteImagePickerOnChangeResult result)
  onChangeHandler;
  final AppliteImagePickerOnChangeResult value;
  final int maxImagesPicked;

  const MultiImagePicker({
    super.key,
    this.initImages = const [],
    required this.onChangeHandler,
    required this.value,
    this.maxImagesPicked = 1,
  });

  @override
  State<MultiImagePicker> createState() => _MultiImagePickerState();
}

class _MultiImagePickerState extends State<MultiImagePicker> {
  List<File> assets = [];
  List<AppliteImagePickerImageUrl> imagesUrls = [];
  List<AppliteImagePickerImageUrl> removedImagesUrls = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    assets = widget.value.assets;
    imagesUrls = widget.value.imagesUrls.isEmpty && widget.initImages.isNotEmpty
        ? widget.initImages
        : widget.value.imagesUrls;
    removedImagesUrls = widget.value.removedImagesUrls;
  }

  deleteHandler({
    required AppliteImagePickerDeleteMode mode,
    required int index,
  }) async {
    final action = await showOkCancelAlertDialog(
      context: context,
      title: "Supprimer",
      message: "Voulez-vous supprimer cette image ?",
      okLabel: "Oui",
      cancelLabel: "Non",
    );

    if (action == OkCancelResult.ok) {
      if (mode == AppliteImagePickerDeleteMode.asset) {
        final assetsClone = [...assets];
        assetsClone.removeAt(index);

        setState(() {
          assets = assetsClone;
        });
      } else {
        final imgs = [...imagesUrls];
        final removed = imgs.removeAt(index);

        setState(() {
          imagesUrls = imgs;
          removedImagesUrls = [...removedImagesUrls, removed];
          widget.onChangeHandler(
            AppliteImagePickerOnChangeResult(
              assets: assets,
              imagesUrls: imagesUrls,
              removedImagesUrls: removedImagesUrls,
            ),
          );
        });
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      // Calculate how many more images can be picked
      final currentCount = assets.length + imagesUrls.length;
      final remainingSlots = widget.maxImagesPicked - currentCount;

      if (remainingSlots <= 0) return;

      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty && mounted) {
        // Limit the number of files to pick based on remaining slots
        final limitedFiles = pickedFiles.take(remainingSlots).toList();
        final List<File> newFiles = limitedFiles
            .map((xFile) => File(xFile.path))
            .toList();

        setState(() {
          assets = [...assets, ...newFiles];
          widget.onChangeHandler(
            AppliteImagePickerOnChangeResult(
              assets: assets,
              imagesUrls: imagesUrls,
              removedImagesUrls: removedImagesUrls,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
      if (mounted) {
        await showOkAlertDialog(
          context: context,
          title: "Erreur",
          message: "Impossible de sélectionner des images. Veuillez réessayer.",
          okLabel: "OK",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final length = assets.length + imagesUrls.length;

    final double size = 150;

    return SizedBox(
      height: size,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...List.generate(
            assets.length,
            (index) => Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => deleteHandler(
                    index: index,
                    mode: AppliteImagePickerDeleteMode.asset,
                  ),
                  child: Image.file(
                    assets[index],
                    height: size,
                    width: size,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          ...List.generate(
            imagesUrls.length,
            (index) => Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => deleteHandler(
                    index: index,
                    mode: AppliteImagePickerDeleteMode.url,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imagesUrls[index].url,
                    height: size,
                    width: size,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          if (length < widget.maxImagesPicked)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                fixedSize: Size.fromWidth(size),
                foregroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
              onPressed: () async {
                await _pickImages();
              },
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedAlbum02,
                size: 28,
                color: Theme.of(context).primaryColor,
              ),
              label: Text(
                "Ajouter une photo",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
