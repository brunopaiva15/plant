import SwiftUI
import WidgetKit

// L'écran du matin, sur l'écran d'accueil et l'écran verrouillé : le chiffre
// du jour, les premières plantes qui attendent, et « Tout est en ordre » le
// reste du temps.
//
// L'extension ne calcule rien et ne traduit rien : l'application écrit un
// instantané (`lib/features/today/application/today_widget.dart`) dans les
// préférences de l'App Group, avec ses libellés dans la langue de
// l'interface ; le widget le lit et le montre. Sans instantané — première
// installation, aperçu de la galerie — il montre un exemple dans la langue
// de l'appareil.

// MARK: - L'instantané

struct TodaySnapshot: Decodable {
  struct Item: Decodable, Identifiable {
    let plantId: String?
    let name: String
    let emoji: String
    let label: String
    let due: String
    let overdue: Bool

    var id: String { "\(plantId ?? "")|\(name)|\(label)" }

    /// La fiche de la plante, ou l'accueil pour une tâche libre.
    var url: URL { URL(string: plantId.map { "auxine://plant/\($0)" } ?? "auxine://today")! }
  }

  struct Labels: Decodable {
    let title: String
    let count: String
    let allDone: String
    let allDoneBody: String
    let empty: String
  }

  let dueCount: Int
  let plantCount: Int
  let labels: Labels
  let tasks: [Item]

  static let group = "group.ch.vergasta.plant"
  static let key = "today"

  static func load() -> TodaySnapshot? {
    guard let json = UserDefaults(suiteName: group)?.string(forKey: key), let data = json.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(TodaySnapshot.self, from: data)
  }

  /// Ce que la galerie des widgets montre, et l'écran tant que
  /// l'application n'a rien écrit : trois plantes, dans la langue de
  /// l'appareil.
  static var sample: TodaySnapshot {
    let w = Words.current
    return TodaySnapshot(
      dueCount: 3,
      plantCount: 12,
      labels: Labels(title: w.title, count: w.count, allDone: w.allDone, allDoneBody: w.allDoneBody, empty: w.empty),
      tasks: [
        Item(plantId: nil, name: "Monstera", emoji: "💧", label: w.water, due: w.today, overdue: false),
        Item(plantId: nil, name: "Pilea", emoji: "💧", label: w.water, due: w.today, overdue: false),
        Item(plantId: nil, name: "Ficus", emoji: "🌱", label: w.fertilize, due: w.today, overdue: false),
      ])
  }
}

/// Les quelques mots de l'exemple et de la galerie, dans les quatre langues
/// de l'application. Tout le reste vient de l'instantané.
struct Words {
  let name: String
  let description: String
  let title: String
  let count: String
  let allDone: String
  let allDoneBody: String
  let empty: String
  let water: String
  let fertilize: String
  let today: String

  static var current: Words {
    switch Locale.current.language.languageCode?.identifier ?? "en" {
    case "fr":
      return Words(name: "Aujourd'hui", description: "Les soins du jour, et les plantes qui attendent.", title: "Aujourd'hui", count: "soins", allDone: "Tout est en ordre", allDoneBody: "Aucun soin prévu aujourd'hui.", empty: "Aucune plante", water: "Arroser", fertilize: "Fertiliser", today: "Aujourd'hui")
    case "de":
      return Words(name: "Heute", description: "Die Pflege des Tages, und die Pflanzen, die warten.", title: "Heute", count: "Aufgaben", allDone: "Alles in Ordnung", allDoneBody: "Heute ist keine Pflege fällig.", empty: "Keine Pflanzen", water: "Gießen", fertilize: "Düngen", today: "Heute")
    case "it":
      return Words(name: "Oggi", description: "Le cure del giorno, e le piante che aspettano.", title: "Oggi", count: "cure", allDone: "Tutto in ordine", allDoneBody: "Nessuna cura prevista oggi.", empty: "Nessuna pianta", water: "Annaffiare", fertilize: "Concimare", today: "Oggi")
    default:
      return Words(name: "Today", description: "Today's care, and the plants that are waiting.", title: "Today", count: "tasks", allDone: "All good", allDoneBody: "No care due today.", empty: "No plants", water: "Water", fertilize: "Fertilize", today: "Today")
    }
  }
}

// MARK: - La palette

/// Les couleurs du design system (docs/06), clair et sombre. Le widget n'a
/// pas accès aux tokens Dart : les valeurs sont recopiées, et à tenir à jour
/// avec `lib/design_system/tokens/colors.dart`.
enum Palette {
  static let canvas = dual(0xF6EFE4, 0x221A15)
  static let surface = dual(0xFBF6EE, 0x2E2219)
  static let ink = dual(0x4A3528, 0xF6EFE4)
  static let inkSecondary = dual(0x6F5A4E, 0xC2AE9C)
  static let sage = dual(0x2C774E, 0x6DC48D)
  static let sageSoft = dual(0xE4EFE6, 0x2C3D31)
  static let terracotta = dual(0x9C482C, 0xE59A70)
  static let terracottaSoft = dual(0xF2D9CB, 0x4A2E22)
  /// Ce qu'on pose sur un accent employé comme fond : clair sur les accents
  /// sombres du thème clair, sombre sur les accents clairs du thème sombre.
  static let onAccent = dual(0xFBF6EE, 0x221A15)
  static let shadow = dual(0x5E2C14, 0x000000)

  private static func dual(_ light: UInt32, _ dark: UInt32) -> Color {
    Color(UIColor { trait in trait.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light) })
  }
}

extension UIColor {
  convenience init(rgb: UInt32) {
    self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255, blue: CGFloat(rgb & 0xFF) / 255, alpha: 1)
  }
}

// MARK: - La ligne du temps

struct TodayEntry: TimelineEntry {
  let date: Date
  let snapshot: TodaySnapshot
}

struct TodayProvider: TimelineProvider {
  func placeholder(in context: Context) -> TodayEntry {
    TodayEntry(date: .now, snapshot: .sample)
  }

  func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
    let snapshot = context.isPreview ? .sample : (TodaySnapshot.load() ?? .sample)
    completion(TodayEntry(date: .now, snapshot: snapshot))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
    let entry = TodayEntry(date: .now, snapshot: TodaySnapshot.load() ?? .sample)
    // L'application réécrit l'instantané à chaque changement et le fait
    // redessiner ; entre deux, on repasse à minuit, quand « aujourd'hui »
    // change de sens.
    let midnight = Calendar.current.nextDate(after: .now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime) ?? Date.now.addingTimeInterval(3600)
    completion(Timeline(entries: [entry], policy: .after(midnight)))
  }
}

// MARK: - Les vues

struct TodayWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: TodayEntry

  private var snapshot: TodaySnapshot { entry.snapshot }

  var body: some View {
    switch family {
    case .accessoryCircular:
      circular.widgetCanvas(.clear)
    case .accessoryRectangular:
      rectangular.widgetCanvas(.clear)
    case .accessoryInline:
      inline.widgetCanvas(.clear)
    case .systemMedium:
      medium.widgetCanvas(Palette.canvas).widgetURL(URL(string: "auxine://today"))
    default:
      small.widgetCanvas(Palette.canvas).widgetURL(URL(string: "auxine://today"))
    }
  }

  // MARK: Écran d'accueil

  private var small: some View {
    VStack(alignment: .leading, spacing: 0) {
      header
      Spacer(minLength: 6)
      if snapshot.dueCount > 0 {
        countBlock
        if let first = snapshot.tasks.first {
          Spacer(minLength: 6)
          taskLine(first, compact: true)
        }
      } else {
        restBlock
      }
    }
  }

  private var medium: some View {
    HStack(alignment: .top, spacing: 14) {
      VStack(alignment: .leading, spacing: 0) {
        header
        Spacer(minLength: 6)
        if snapshot.dueCount > 0 { countBlock } else { restBlock }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      if snapshot.dueCount > 0 {
        VStack(alignment: .leading, spacing: 8) {
          ForEach(snapshot.tasks.prefix(3)) { task in
            Link(destination: task.url) { taskLine(task, compact: false) }
          }
          Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }

  private var header: some View {
    HStack(spacing: 6) {
      Image(systemName: "leaf.fill")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(Palette.sage)
      Text(snapshot.labels.title)
        .font(.system(.caption, design: .rounded).weight(.semibold))
        .foregroundStyle(Palette.inkSecondary)
        .lineLimit(1)
    }
  }

  /// Le chiffre du matin, sur sa pièce de terre cuite : la seule couleur
  /// pleine du widget, comme sur l'écran Aujourd'hui.
  private var countBlock: some View {
    HStack(alignment: .firstTextBaseline, spacing: 6) {
      Text("\(snapshot.dueCount)")
        .font(.system(size: 40, weight: .bold, design: .rounded))
        .foregroundStyle(Palette.onAccent)
      Text(snapshot.labels.count)
        .font(.system(.subheadline, design: .rounded).weight(.bold))
        .foregroundStyle(Palette.onAccent)
        .lineLimit(2)
        .minimumScaleFactor(0.8)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity, alignment: .leading)
    .clay(Palette.terracotta)
  }

  /// Rien à faire, ou rien à soigner : la carte de repos reste crème.
  private var restBlock: some View {
    HStack(alignment: .top, spacing: 8) {
      Text(snapshot.plantCount == 0 ? "🪴" : "🌿")
        .font(.system(size: 22))
      VStack(alignment: .leading, spacing: 2) {
        Text(snapshot.plantCount == 0 ? snapshot.labels.empty : snapshot.labels.allDone)
          .font(.system(.subheadline, design: .rounded).weight(.bold))
          .foregroundStyle(Palette.ink)
        if snapshot.plantCount > 0 {
          Text(snapshot.labels.allDoneBody)
            .font(.caption)
            .foregroundStyle(Palette.inkSecondary)
        }
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .clay(Palette.surface)
  }

  private func taskLine(_ task: TodaySnapshot.Item, compact: Bool) -> some View {
    HStack(spacing: 6) {
      Text(task.emoji).font(.system(size: compact ? 12 : 14))
      VStack(alignment: .leading, spacing: 0) {
        Text(task.name)
          .font(.system(.caption, design: .rounded).weight(.semibold))
          .foregroundStyle(Palette.ink)
          .lineLimit(1)
        if !compact {
          Text(task.label.isEmpty ? task.due : "\(task.label) · \(task.due)")
            .font(.caption2)
            .foregroundStyle(task.overdue ? Palette.terracotta : Palette.inkSecondary)
            .lineLimit(1)
        }
      }
      Spacer(minLength: 0)
    }
  }

  // MARK: Écran verrouillé

  private var circular: some View {
    ZStack {
      AccessoryWidgetBackground()
      VStack(spacing: -2) {
        Image(systemName: "leaf.fill").font(.system(size: 11, weight: .semibold))
        Text("\(snapshot.dueCount)").font(.system(size: 22, weight: .bold, design: .rounded))
      }
    }
  }

  private var rectangular: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(spacing: 4) {
        Image(systemName: "leaf.fill").font(.system(size: 11, weight: .semibold))
        Text(snapshot.dueCount > 0 ? "\(snapshot.dueCount) \(snapshot.labels.count)" : snapshot.labels.title)
          .font(.headline)
          .lineLimit(1)
      }
      if snapshot.dueCount == 0 {
        Text(snapshot.plantCount == 0 ? snapshot.labels.empty : snapshot.labels.allDone).font(.caption).lineLimit(1)
      } else {
        ForEach(snapshot.tasks.prefix(2)) { task in
          Text("\(task.emoji) \(task.name)").font(.caption).lineLimit(1)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var inline: some View {
    Text(snapshot.dueCount > 0 ? "🌿 \(snapshot.dueCount) \(snapshot.labels.count)" : "🌿 \(snapshot.labels.allDone)")
  }
}

// MARK: - La matière

extension View {
  /// Une pièce d'argile : le fond plein, un reflet en haut à gauche, une ombre
  /// portée dans sa teinte en bas à droite — la recette de `ClayBox`, en plus
  /// simple, à l'échelle d'un widget.
  func clay(_ color: Color) -> some View {
    background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(color)
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(
              LinearGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0), Color.black.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing),
              lineWidth: 1.5))
        .shadow(color: Palette.shadow.opacity(0.16), radius: 5, x: 2, y: 3)
    )
  }

  /// Le fond du widget, selon la version d'iOS : le conteneur du système
  /// depuis iOS 17, qui met les marges lui-même ; avant, on les pose.
  @ViewBuilder
  func widgetCanvas(_ color: Color) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) { color }
    } else {
      padding(14).frame(maxWidth: .infinity, maxHeight: .infinity).background(color)
    }
  }
}

// MARK: - Le widget

struct TodayWidget: Widget {
  let kind = "ch.vergasta.plant.today"

  var body: some WidgetConfiguration {
    let words = Words.current
    return StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
      TodayWidgetView(entry: entry)
    }
    .configurationDisplayName(Text(verbatim: words.name))
    .description(Text(verbatim: words.description))
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
  }
}

@main
struct AuxineWidgetBundle: WidgetBundle {
  var body: some Widget {
    TodayWidget()
  }
}
