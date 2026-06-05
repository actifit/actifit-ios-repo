//
//  HistoryChartVC.swift
//  Actifit
//
//  Created by Srini on 22/01/19.
//

import UIKit
import Charts

class HistoryChartVC: UIViewController,ChartViewDelegate {

    @IBOutlet weak var barChart: BarChartView!
    
    var history = [Activity]()
    var labels = [String]()
    var entries = [BarChartDataEntry]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var i:Int = history.count - 1
        for tempData in history{
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.current
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let tempLabel = dateFormatter.string(from: tempData.date)
            labels.append(tempLabel)
            entries.append(BarChartDataEntry(x: Double(i), y: Double(tempData.steps)))
            i -= 1
        }
        labels.reverse()
        entries.reverse()
        print(labels)
        print(entries)
        let xAxis = barChart.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.granularity = 1
        xAxis.labelCount = 7
        xAxis.valueFormatter = DayAxisValueFormatter(chart: barChart, labels: labels) as AxisValueFormatter
        
        let line = ChartLimitLine(limit: 5000, label: "Min Reward - 5K Activity")
        line.lineColor = .primaryRedColor()
        line.valueTextColor = .black
        line.valueFont = .systemFont(ofSize: 10)
        line.lineWidth = 4

        let leftAxisFormatter = NumberFormatter()
        leftAxisFormatter.minimumFractionDigits = 0
        leftAxisFormatter.maximumFractionDigits = 1
        leftAxisFormatter.negativeSuffix = ""
        leftAxisFormatter.positiveSuffix = ""
        
        
        let leftAxis = barChart.leftAxis
        leftAxis.labelFont = .systemFont(ofSize: 10)
        leftAxis.labelCount = 8
        leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: leftAxisFormatter)
        leftAxis.labelPosition = .outsideChart
        leftAxis.spaceTop = 0.15
        leftAxis.axisMinimum = 0
        leftAxis.addLimitLine(line)
        
        let rightAxis = barChart.rightAxis
        rightAxis.enabled = true
        rightAxis.labelFont = .systemFont(ofSize: 10)
        rightAxis.labelCount = 8
        rightAxis.valueFormatter = leftAxis.valueFormatter
        rightAxis.spaceTop = 0.15
        rightAxis.axisMinimum = 0
        
        barChart.delegate = self
        let set1 = BarChartDataSet(entries: entries, label: "The year 2019")
        let data = BarChartData(dataSet: set1)
        data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 10)!)
        data.barWidth = 0.1
        barChart.data = data
    }
    
    @IBAction func backBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
