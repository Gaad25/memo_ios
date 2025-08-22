// memo/Features/Statistics/StatisticsView.swift

import SwiftUI
import Charts

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @Namespace private var filterNS

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else if viewModel.subjectPerformances.isEmpty && viewModel.weeklyDistribution.allSatisfy({$0.minutes == 0}) {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 56))
                                .foregroundStyle(Color.dsPrimary)
                                .symbolRenderingMode(.hierarchical)
                            Text("Sem dados por enquanto")
                                .font(.title3.bold())
                                .foregroundStyle(Color.dsTextPrimary)
                            Text("Registre suas sessões de estudo para ver insights e acompanhar sua evolução por matéria.")
                                .font(.subheadline)
                                .foregroundStyle(Color.dsTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(32)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.dsSecondaryBackground))
                        .padding(.top, 24)
                    } else {
                        // Filtro de período
                        periodFilter

                        // Gráfico 1: Tempo de Estudo por Matéria
                        let timeData = viewModel.subjectPerformances.filter { $0.totalMinutes > 0 }
                        if !timeData.isEmpty {
                            chartCard(title: "Tempo de Estudo por Matéria", subtitle: "Total de minutos por disciplina no período selecionado") {
                                Chart(timeData) { performance in
                                    BarMark(
                                        x: .value("Matéria", performance.name),
                                        y: .value("Minutos", performance.totalMinutes)
                                    )
                                    .foregroundStyle(performance.color.gradient)
                                    .annotation(position: .top) {
                                        Text("\(performance.totalMinutes)m")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .accessibilityLabel(Text(performance.name))
                                    .accessibilityValue(Text("\(performance.totalMinutes) minutos"))
                                }
                                .chartXAxis {
                                    AxisMarks { AxisValueLabel().font(.footnote) }
                                }
                                .chartYAxis {
                                    AxisMarks { AxisGridLine(); AxisValueLabel().font(.footnote) }
                                }
                                .chartYAxisLabel("Minutos")
                                .frame(height: 260)
                                .sensoryFeedback(.impact(weight: .light), trigger: timeData.count)
                            }
                        }

                        // Gráfico 2: Taxa de Acerto por Matéria
                        let accuracyData = viewModel.subjectPerformances.filter { $0.accuracy > 0 && $0.accuracy.isFinite }
                        if !accuracyData.isEmpty {
                            chartCard(title: "Taxa de Acerto por Matéria", subtitle: "Percentual de acertos por disciplina") {
                                Chart(accuracyData) { performance in
                                    BarMark(
                                        x: .value("Acertos (%)", performance.accuracy * 100),
                                        y: .value("Matéria", performance.name)
                                    )
                                    .foregroundStyle(performance.color.gradient)
                                    .annotation(position: .trailing) {
                                        Text("\(Int(performance.accuracy * 100))%")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .accessibilityLabel(Text(performance.name))
                                    .accessibilityValue(Text("\(Int(performance.accuracy * 100)) por cento"))
                                }
                                .chartYAxis { AxisMarks(position: .leading) { AxisValueLabel().font(.footnote) } }
                                .frame(height: max(200, CGFloat(accuracyData.count) * 44))
                                .sensoryFeedback(.impact(weight: .light), trigger: accuracyData.count)
                            }
                        }

                        // Heatmap: Distribuição Semanal de Estudo
                        let weeklyData = viewModel.weeklyDistribution
                        if !weeklyData.isEmpty {
                            chartCard(title: "Distribuição Semanal de Estudo", subtitle: "Minutos por dia na última semana") {
                                HStack(alignment: .bottom, spacing: 12) {
                                    ForEach(weeklyData) { day in
                                        VStack(spacing: 8) {
                                            Text(day.id)
                                                .font(.footnote)
                                                .foregroundStyle(Color.dsTextSecondary)
                                            HeatCell(colors: day.subjectColors,
                                                     opacity: opacity(for: day.minutes))
                                            .accessibilityLabel("\(fullDayName(for: day.id)), \(day.minutes) minutos de estudo")
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Estatísticas")
            .onAppear {
                viewModel.startFetching()
            }
            .onDisappear {
                viewModel.cancelFetching()
            }
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
}

// MARK: - Subviews & Helpers
private extension StatisticsView {
    func opacity(for minutes: Int) -> Double {
        let maxMins = max(1, viewModel.maxDailyMinutes)
        let raw = Double(minutes) / Double(maxMins)
        // Mínimo visual para zero
        return max(0.1, min(1.0, raw))
    }

    func fullDayName(for short: String) -> String {
        switch short {
        case "Dom": return "Domingo"
        case "Seg": return "Segunda-feira"
        case "Ter": return "Terça-feira"
        case "Qua": return "Quarta-feira"
        case "Qui": return "Quinta-feira"
        case "Sex": return "Sexta-feira"
        case "Sáb": return "Sábado"
        default: return short
        }
    }
    @ViewBuilder
    var periodFilter: some View {
        HStack(spacing: 8) {
            ForEach(TimeFilter.allCases, id: \.self) { filter in
                let isSelected = viewModel.selectedFilter == filter
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                        viewModel.setFilter(filter)
                    }
                } label: {
                    Text(label(for: filter))
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(isSelected ? Color.dsPrimary : Color.dsChipBackground)
                        )
                        .foregroundStyle(isSelected ? .white : .primary)
                        .matchedGeometryEffect(id: "period_\(filter.rawValue)", in: filterNS)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Filtro de período \(label(for: filter))")
            }
        }
        .padding(.horizontal, 4)
    }

    func label(for filter: TimeFilter) -> String {
        switch filter {
        case .week: return "7 dias"
        case .month: return "30 dias"
        case .quarter: return "90 dias"
        }
    }

    @ViewBuilder
    func chartCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.dsTextPrimary)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Color.dsTextSecondary)
            }
            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.dsSecondaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06))
        )
    }
}

// MARK: - Heat Cell
private struct HeatCell: View {
    let colors: [Color]
    let opacity: Double
    var body: some View {
        let base: AnyShapeStyle
        if colors.isEmpty {
            base = AnyShapeStyle(Color.dsSecondaryBackground)
        } else if colors.count == 1 {
            base = AnyShapeStyle(colors[0])
        } else {
            base = AnyShapeStyle(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        return RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(base)
            .opacity(opacity)
            .frame(width: 28, height: 80)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06))
            )
    }
}
