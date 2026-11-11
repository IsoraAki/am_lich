package com.isora.am_lich

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.widget.RemoteViews
import java.time.LocalDate
import java.time.ZoneId

class LunarWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val today = LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"))
        val epochDay = today.toEpochDay()
        val month = context.assets.open("widget_months.csv").bufferedReader().useLines { lines ->
            lines.map { row -> row.split(",").map(String::toLong) }
                .lastOrNull { row -> row[0] <= epochDay }
        }
        // Same stable daily shuffle as calendar_colors.dart and the iOS widget.
        val backgrounds = intArrayOf(
            R.drawable.widget_background, R.drawable.widget_indigo,
            R.drawable.widget_berry, R.drawable.widget_terracotta,
            R.drawable.widget_moss, R.drawable.widget_plum
        )
        val shuffled = (epochDay * 37) xor (epochDay shr 3) xor (epochDay shr 5)
        val colorIndex = Math.floorMod(shuffled, backgrounds.size.toLong()).toInt()
        var dayText = "—"
        var monthText = "Hỗ trợ năm 1900–2199"
        var compactMonthText = monthText
        if (month != null && today.year in 1900..2199) {
            val lunarDay = epochDay - month[0] + 1
            val lunarMonth = month[1].toInt()
            val dayBranch = ((epochDay + 2440588 + 1) % 12).toInt()
            val spirit = Math.floorMod(dayBranch - 2 * (lunarMonth - 1), 12)
            val kind = if (spirit in setOf(0, 1, 4, 5, 7, 10)) "Hoàng đạo" else "Hắc đạo"
            val label = "Tháng $lunarMonth${if (month[2] == 1L) " nhuận" else ""}"
            dayText = lunarDay.toString().padStart(2, '0')
            monthText = "$label âm lịch · $kind"
            compactMonthText = "$label · $kind"
        }
        val weekdays = listOf("Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ nhật")
        val solarDate = "${today.dayOfMonth}/${today.monthValue}/${today.year}"
        val solarText = "${weekdays[today.dayOfWeek.value - 1]} · $solarDate"
        val launch = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pending = PendingIntent.getActivity(
            context, 0, launch, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        fun render(layout: Int, monthLabel: String, dateLabel: String) =
            RemoteViews(context.packageName, layout).apply {
                setInt(R.id.widget_root, "setBackgroundResource", backgrounds[colorIndex])
                setTextViewText(R.id.lunar_day, dayText)
                setTextViewText(R.id.lunar_month, monthLabel)
                setTextViewText(R.id.solar_date, dateLabel)
                setOnClickPendingIntent(R.id.widget_root, pending)
            }

        val compact = render(R.layout.lunar_widget_compact, compactMonthText, solarDate)
        val regular = render(R.layout.lunar_widget, monthText, solarText)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val responsive = RemoteViews(mapOf(
                SizeF(180f, 48f) to compact,
                SizeF(180f, 140f) to regular
            ))
            ids.forEach { id -> manager.updateAppWidget(id, responsive) }
        } else {
            ids.forEach { id ->
                val height = manager.getAppWidgetOptions(id)
                    .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 140)
                manager.updateAppWidget(id, if (height in 1 until 140) compact else regular)
            }
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle
    ) {
        onUpdate(context, manager, intArrayOf(appWidgetId))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action in listOf(
                Intent.ACTION_DATE_CHANGED, Intent.ACTION_TIME_CHANGED,
                Intent.ACTION_TIMEZONE_CHANGED, Intent.ACTION_BOOT_COMPLETED,
                Intent.ACTION_MY_PACKAGE_REPLACED
            )) {
            val manager = AppWidgetManager.getInstance(context)
            onUpdate(context, manager, manager.getAppWidgetIds(
                ComponentName(context, LunarWidgetProvider::class.java)
            ))
        }
    }
}
