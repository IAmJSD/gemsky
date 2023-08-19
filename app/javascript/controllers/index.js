// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

import ContentWarningController from "./content_warning_controller"
application.register("content-warning", ContentWarningController)

import DialogController from "./dialog_controller"
application.register("dialog", DialogController)

import DialogToggleController from "./dialog_toggle_controller"
application.register("dialog-toggle", DialogToggleController)

import NotificationCountController from "./notification_count_controller"
application.register("notification-count", NotificationCountController)

import TwemojiController from "./twemoji_controller"
application.register("twemoji", TwemojiController)
