package com.isora.am_lich

import android.app.AlarmManager
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
import java.time.ZoneId
import java.time.ZonedDateTime

class LunarWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val ACTION_REFRESH_DATE = "com.isora.am_lich.REFRESH_WIDGET_DATE"
        private val vietnamZone = ZoneId.of("Asia/Ho_Chi_Minh")

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val provider = ComponentName(context, LunarWidgetProvider::class.java)
            LunarWidgetProvider().onUpdate(context, manager, manager.getAppWidgetIds(provider))
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        if (ids.isEmpty()) return
        val today = ZonedDateTime.now(vietnamZone).toLocalDate()
        val midnight = today.plusDays(1).atStartOfDay(vietnamZone).toInstant().toEpochMilli()
        context.getSystemService(AlarmManager::class.java).setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP, midnight, refreshIntent(context)
        )
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
        var narrowMonthText = "1900–2199"
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
            narrowMonthText = label
        }
        val weekdays = listOf("Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ nhật")
        val shortSolarDate = "${today.dayOfMonth}/${today.monthValue}"
        val solarDate = "$shortSolarDate/${today.year}"
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

        val narrow = render(R.layout.lunar_widget_compact, narrowMonthText, "DL $shortSolarDate")
        val compact = render(R.layout.lunar_widget_compact, compactMonthText, solarDate)
        val regular = render(R.layout.lunar_widget, monthText, solarText)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val responsive = RemoteViews(mapOf(
                SizeF(90f, 48f) to narrow,
                SizeF(180f, 48f) to compact,
                SizeF(180f, 140f) to regular
            ))
            ids.forEach { id -> manager.updateAppWidget(id, responsive) }
        } else {
            ids.forEach { id ->
                val options = manager.getAppWidgetOptions(id)
                val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 90)
                val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 48)
                val views = when {
                    width < 180 -> narrow
                    height < 140 -> compact
                    else -> regular
                }
                manager.updateAppWidget(id, views)
            }
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context, manager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle
    ) {
        onUpdate(context, manager, intArrayOf(appWidgetId))
    }

    override fun onDisabled(context: Context) {
        context.getSystemService(AlarmManager::class.java).cancel(refreshIntent(context))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_REFRESH_DATE, Intent.ACTION_TIME_CHANGED, Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> refreshAll(context)
        }
    }

    private fun refreshIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, LunarWidgetProvider::class.java).setAction(ACTION_REFRESH_DATE),
        PendingIntent.FLAG_IMMUTABLE
    )
}
