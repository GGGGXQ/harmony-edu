/**
 * Icon system — SVG icons loaded from resources/base/media/
 * All SVGs are 24x24 viewBox, stroke-based, designed for fillColor tinting.
 * Set size via .width()/.height() and color via .fillColor() on the Image.
 */

@Builder
export function IconChevronLeft(size: number, color: ResourceColor) {
  Image($r('app.media.icon_chevron_left'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}

@Builder
export function IconChevronRight(size: number, color: ResourceColor) {
  Image($r('app.media.icon_chevron_right'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}

@Builder
export function IconHome(size: number, color: ResourceColor) {
  Image($r('app.media.icon_home'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}

@Builder
export function IconClock(size: number, color: ResourceColor) {
  Image($r('app.media.icon_clock'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}

@Builder
export function IconUser(size: number, color: ResourceColor) {
  Image($r('app.media.icon_user'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}

@Builder
export function IconTrash(size: number, color: ResourceColor) {
  Image($r('app.media.icon_trash'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}

@Builder
export function IconSend(size: number, color: ResourceColor) {
  Image($r('app.media.icon_send'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}

@Builder
export function IconSettings(size: number, color: ResourceColor) {
  Image($r('app.media.icon_settings'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}

@Builder
export function IconLogOut(size: number, color: ResourceColor) {
  Image($r('app.media.icon_log_out'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}

@Builder
export function IconAlertCircle(size: number, color: ResourceColor) {
  Image($r('app.media.icon_alert_circle'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}

@Builder
export function IconCheckCircle(size: number, color: ResourceColor) {
  Image($r('app.media.icon_check_circle'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}

@Builder
export function IconBookOpen(size: number, color: ResourceColor) {
  Image($r('app.media.icon_book_open'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}

@Builder
export function IconMessageCircle(size: number, color: ResourceColor) {
  Image($r('app.media.icon_message_circle'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}

@Builder
export function IconSparkle(size: number, color: ResourceColor) {
  Image($r('app.media.icon_sparkle'))
    .width(size).height(size)
    .fillColor(color)
    .objectFit(ImageFit.Contain)
}
