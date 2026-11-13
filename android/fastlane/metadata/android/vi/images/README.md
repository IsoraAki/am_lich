# Google Play Image Uploads

Place Google Play listing images in this folder using Fastlane's expected names.

## Upload Locations

- App logo: put one PNG/JPEG in `icon/`
- Featured image: put one PNG/JPEG in `featureGraphic/`
- Phone screenshots: `phoneScreenshots/`
- 7-inch tablet screenshots: `sevenInchScreenshots/`

Fastlane uploads the app logo from `icon.png`, `icon.jpg`, or `icon.jpeg` in this folder. The deploy lane stages the image from `icon/` into that required filename automatically.

Fastlane uploads the featured image from `featureGraphic.png`, `featureGraphic.jpg`, or `featureGraphic.jpeg` in this folder. The deploy lane stages the image from `featureGraphic/` into that required filename automatically.

Run this before deploying:

```sh
dart auto/check_play_images.dart
```
