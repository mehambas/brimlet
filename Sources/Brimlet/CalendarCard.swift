import SwiftUI
import BrimletCore

struct CalendarCard: View {
    @ObservedObject var module: CalendarModule

    var body: some View {
        switch module.access {
        case .notRequested, .failed:
            EmptyCard(symbol: "calendar", title: "Your calendar, up top", subtitle: module.access == .failed ? "Couldn’t connect to Calendar. You can try again." : "Allow calendar access to see your upcoming events.", actionTitle: "Connect Calendar") { module.requestAccess() }
        case .requesting:
            VStack(spacing: 12) {
                ProgressView().controlSize(.small)
                Text("Waiting for calendar access…").font(.system(size: 12)).foregroundStyle(BrimletTheme.secondary)
            }.frame(maxWidth: .infinity).frame(height: 158)
        case .denied, .restricted:
            EmptyCard(symbol: "lock.shield", title: "Calendar access is off", subtitle: module.access == .restricted ? "Calendar access is restricted on this Mac." : "Turn on full access in System Settings › Privacy & Security › Calendars.", actionTitle: "Open System Settings") { module.openPrivacySettings() }
        case .ready:
            agenda
        }
    }

    private var agenda: some View {
        VStack(spacing: 7) {
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    ForEach(AgendaRange.allCases) { range in
                        Button { module.agendaRange = range } label: {
                            Text(range.title).font(.system(size: 12, weight: .medium))
                                .frame(maxWidth: .infinity).frame(height: 28)
                        }.buttonStyle(IslandSelectionStyle(selected: module.agendaRange == range))
                            .accessibilityAddTraits(module.agendaRange == range ? .isSelected : [])
                    }
                }.accessibilityLabel("Agenda")
                IconButton(symbol: "arrow.clockwise", help: "Refresh Calendar") { module.refresh() }
                IconButton(symbol: "calendar", help: "Open Calendar") { module.openCalendar() }
            }
            if let error = module.actionError {
                Text(error).font(.system(size: 11)).foregroundStyle(.orange)
            }
            if module.loading && module.events.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if module.agenda.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.checkmark").font(.system(size: 23)).foregroundStyle(BrimletTheme.secondary)
                    Text("No events in this range").font(.system(size: 13, weight: .medium))
                    Text("Choose which calendars to show in Settings.")
                        .font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(module.agenda) { event in eventRow(event) }
                    }
                }.id(module.agendaRange)
            }
        }.padding(.horizontal, 20).frame(height: 192)
    }

    private func eventRow(_ event: CalendarEvent) -> some View {
        HStack(spacing: 10) {
            Button { module.openEvent(event) } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title).font(.system(size: 12, weight: .semibold)).lineLimit(2)
                    HStack(spacing: 4) {
                        Text(event.status(at: module.now))
                            .foregroundStyle(event.start <= module.now && event.end > module.now ? BrimletTheme.mint : BrimletTheme.primary)
                        Text("·")
                        Text(schedule(event)).lineLimit(1)
                        Text("·")
                        if let color = event.calendarColorRGB { Circle().fill(Color(hex: color)).frame(width: 7, height: 7).accessibilityHidden(true) }
                        Text(event.calendarTitle).lineLimit(1)
                    }.font(.system(size: 11)).foregroundStyle(BrimletTheme.secondary)

                }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.plain).help("Show in Calendar")
            if event.meetingURL != nil && event.end > module.now {
                Button("Join") { module.openMeeting(event) }.buttonStyle(MintButtonStyle(prominent: event.start.timeIntervalSince(module.now) <= 600))
                    .accessibilityLabel("Join \(event.title)")
            }
            IconButton(symbol: "arrow.up.right", help: "Show in Calendar") { module.openEvent(event) }
        }.padding(.horizontal, 10).padding(.vertical, 8).background(BrimletTheme.surface, in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(event.end <= module.now ? BrimletTheme.tertiary : BrimletTheme.primary)
    }

    private func schedule(_ event: CalendarEvent) -> String {
        let day = module.agendaRange == .week ? (Calendar.current.isDateInToday(event.start) ? String(localized: "Today") : event.start.formatted(.dateTime.day().month())) + " · " : ""
        if event.isAllDay { return day + String(localized: "All day") }
        return "\(day)\(event.start.formatted(date: .omitted, time: .shortened)) – \(event.end.formatted(date: .omitted, time: .shortened))"
    }
}
