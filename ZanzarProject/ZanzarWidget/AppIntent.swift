//
//  AppIntent.swift
//  ZanzarWidget
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "widget.configuration.title" }
    static var description: IntentDescription { "widget.configuration.description" }
}