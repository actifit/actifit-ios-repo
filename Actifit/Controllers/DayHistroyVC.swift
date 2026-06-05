//
//  DayHistroyVC.swift
//  Actifit
//
//  Created by Deepak Bansal on 08/07/19.
//

import UIKit
import Charts



class DayHistroyVC: UIViewController,ChartViewDelegate {
    
    @IBOutlet weak var barChart: BarChartView!
    
    var history = [Activity]()
    var labels = [String]()
    var entries = [BarChartDataEntry]()
    //  var months: [String]!
    let months = ["Jan", "Feb", "Mar", "Apr", "May"]
    let unitsSold = [20.0, 4.0, 6.0, 3.0, 12.0]
    let unitsBought = [10.0, 14.0, 60.0, 13.0, 2.0]
    
    
    public var selectedDate = Date()
    var entriesFifteenMinuteIntervel = [BarChartDataEntry]()
    var dailyLabels = [String]()
    var TimeSlot = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        barEntry()
    }
    
   
    func setChart() {
        barChart.noDataText = "You need to provide data for the chart."
        var dataEntries: [BarChartDataEntry] = []
        var dataEntries1: [BarChartDataEntry] = []
        var dataEntries2: [BarChartDataEntry] = []
        
        for i in 0..<self.months.count {
            
            let dataEntry = BarChartDataEntry(x: Double(i) , y: self.unitsSold[i])
            dataEntries.append(dataEntry)
            
            let dataEntry1 = BarChartDataEntry(x: Double(i) , y: self.self.unitsBought[i])
            dataEntries1.append(dataEntry1)
            
            let dataEntry2 = BarChartDataEntry(x: Double(i) , y: self.self.unitsBought[i])
            dataEntries2.append(dataEntry2)
            
            //stack barchart
            //let dataEntry = BarChartDataEntry(x: Double(i), yValues:  [self.unitsSold[i],self.unitsBought[i]], label: "groupChart")
            
            
            
        }
        
        let chartDataSet = BarChartDataSet(entries: dataEntries, label: "Unit sold")
        let chartDataSet1 = BarChartDataSet(entries: dataEntries1, label: "")
        let chartDataSet2 = BarChartDataSet(entries: dataEntries2, label: "")
        
        let dataSets: [BarChartDataSet] = [chartDataSet,chartDataSet1,chartDataSet2]
        // chartDataSet.colors = [UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)]
        //chartDataSet.colors = ChartColorTemplates.colorful()
        //let chartData = BarChartData(dataSet: chartDataSet)
        
        let chartData = BarChartData(dataSets: dataSets)
        
        
        let groupSpace = 0.3
        let barSpace = 0.01
        let barWidth = 0.1
        // (0.3 + 0.05) * 2 + 0.3 = 1.00 -> interval per "group"
        
        let groupCount = self.months.count
        let startYear = 0
        
        
        chartData.barWidth = barWidth;
        barChart.xAxis.axisMinimum = Double(startYear)
        let gg = chartData.groupWidth(groupSpace: groupSpace, barSpace: barSpace)
        print("Groupspace: \(gg)")
        barChart.xAxis.axisMaximum = Double(startYear) + gg * Double(groupCount)
        
        chartData.groupBars(fromX: Double(startYear), groupSpace: groupSpace, barSpace: barSpace)
        //chartData.groupWidth(groupSpace: groupSpace, barSpace: barSpace)
        barChart.notifyDataSetChanged()
        
        barChart.data = chartData
        
        
        
        
        
        
        //background color
        barChart.backgroundColor = UIColor(red: 189/255, green: 195/255, blue: 199/255, alpha: 1)
        
        //chart animation
        barChart.animate(xAxisDuration: 1.5, yAxisDuration: 1.5, easingOption: .linear)
        
        
    }
    
    
    
    func barEntry()  {
        var data_id = 0
        let indHr = Int()
        let indMin = Int()
        let hoursInDay = 24;
        let minInt = [0,15,30,45]
        let minSlots = minInt.count
        
        var labels = [String](repeating: String(), count: hoursInDay * minSlots)
        entriesFifteenMinuteIntervel    = []
        dailyLabels                     = []
        
        for indHr in 0..<hoursInDay
        {
            for indMin in indMin..<minSlots{
                var slotLabel = "" + "\(indHr)";
                if indHr < 10 {
                    slotLabel =  "0" + "\(indHr)";
                }
                labels[data_id] = slotLabel + ":";
                if (minInt[indMin] < 10) {
                    slotLabel +=  "\(minInt[indMin])";
                    labels[data_id] +=  "0" + "\(minInt[indMin])";
                } else {
                    slotLabel += "\(minInt[indMin])";
                    labels[data_id] += "\(minInt[indMin])";
                }
                var  matchingSlot = -1;
                data_id += 1;
            }
            TimeSlot = labels
        }
        var k:Int = TimeSlot.count - 1
        for i in  TimeSlot {
            
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale.current
            dateFormatter.dateFormat = "HH:mm"
            let tempLabel = dateFormatter.date(from: i)
            
            if tempLabel == nil{
                dailyLabels.append("00:00")
            }else{
                let temp  =  dateFormatter.string(from: tempLabel!)
                dailyLabels.append(temp)
            }
            
            var step = i
            
            var contents = [ActivityFifteenMinutesInterval]()
            
            let allsavedRecordsOfHistory = AllRecordsOfActivitiesNew.all()
            let selectedDateHistory = allsavedRecordsOfHistory.filter({$0.date == self.selectedDate.dateString()})
            var activitiesDataList : [ActivityFifteenMinutesInterval] = []
            if selectedDateHistory.count > 0{
                let decoder = JSONDecoder()
                do {
                    let decoded = try decoder.decode([ActivityFifteenMinutesInterval].self, from: selectedDateHistory[0].activitiesListData!)
                    print(decoded[0])
                    
                    
                    for activityObj in decoded{
                        let activity = ActivityFifteenMinutesInterval()
                        activity.id = Int(activityObj.idInString) ?? 0
                        activity.date = activityObj.date
                        activity.interval = activityObj.interval
                        activity.steps = Int(activityObj.stepsInString) ?? 0
                        activitiesDataList.append(activity)
                    }
                    
                    
                } catch {
                    print("Failed to decode JSON")
                }
                
                
                
                
//                if let anArrayOfPersonsRetrieved = NSKeyedUnarchiver.unarchiveObject(with: selectedDateHistory[0].activitiesListData) as? [ActivityFifteenMinutesInterval] {
//                    for activityObj in anArrayOfPersonsRetrieved{
//                        let activity = ActivityFifteenMinutesInterval()
//                        activity.id = Int(activityObj.idInString) ?? 0
//                        activity.date = activityObj.date
//                        activity.interval = activityObj.interval
//                        activity.steps = Int(activityObj.stepsInString) ?? 0
//                        activitiesDataList.append(activity)
//                    }
//                }
            }else{
                return
            }
            
            let dataList = activitiesDataList
            step    = step.replacingOccurrences(of: ":", with: ".")
            
            let time = TimeSlot[k].replacingOccurrences(of: ":", with: ".")
            contents = dataList.filter({$0.interval == i})
            
            
            if !contents.isEmpty {
                if (contents[0].steps) > 0{
                    let time2 = contents[0].interval.replacingOccurrences(of: ":", with: ".")
                    entriesFifteenMinuteIntervel.append(BarChartDataEntry(x: Double(time2)! * 4.02, y: Double(contents[0].steps)))
                }
            }
            k = k - 1
        }
        
        let xAxis = barChart.xAxis
        xAxis.labelPosition = .top
        xAxis.labelFont = .systemFont(ofSize: 8)
        xAxis.granularityEnabled = true
        xAxis.granularity = 1.0
        xAxis.labelCount = 96
        xAxis.wordWrapEnabled = true
        xAxis.valueFormatter = IndexAxisValueFormatter(values: dailyLabels)
        
        let leftAxisFormatter = NumberFormatter()
        leftAxisFormatter.minimumFractionDigits = 0
        leftAxisFormatter.maximumFractionDigits = 1
        leftAxisFormatter.negativeSuffix = ""
        leftAxisFormatter.positiveSuffix = ""
        
        
        
        let leftAxis = barChart.leftAxis
        leftAxis.labelFont = .systemFont(ofSize: 8)
        leftAxis.labelCount = 8
        leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: leftAxisFormatter)
        leftAxis.labelPosition = .outsideChart
        leftAxis.spaceTop = 0.15
        leftAxis.axisMinimum = 0
        
        
        
        let rightAxis = barChart.rightAxis
        rightAxis.enabled = true
        rightAxis.labelFont = .systemFont(ofSize: 8)
        rightAxis.labelCount = 8
        rightAxis.valueFormatter = leftAxis.valueFormatter
        rightAxis.spaceTop = 0.15
        
        rightAxis.axisMinimum = 0
        
        barChart.delegate = self
        let set1 = BarChartDataSet(entries: entriesFifteenMinuteIntervel, label: "Activity Details")
        let data = BarChartData(dataSet: set1)
        data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 8)!)
        data.barWidth = 0.1
        
        
        barChart.data = data
        
       
        if entriesFifteenMinuteIntervel.count > 10{
            barChart.zoom(scaleX: 7, scaleY: 0, x: 0, y: 0)
            barChart.setScaleMinima(6.0, scaleY: 0.0)
        }else if entriesFifteenMinuteIntervel.count >= 7{
            barChart.zoom(scaleX: 3.5, scaleY: 0, x: 0, y: 0)
            barChart.zoom(scaleX: 3.0, scaleY: 0, x: 0, y: 0)
        }else if entriesFifteenMinuteIntervel.count > 5{
            barChart.zoom(scaleX: 1.5, scaleY: 0, x: 0, y: 0)
            barChart.zoom(scaleX: 1.5, scaleY: 0, x: 0, y: 0)
        }
        
//        if entriesFifteenMinuteIntervel.count > 15{
//             barChart.zoom(scaleX: 7, scaleY: 0, x: 0, y: 0)
//             barChart.setScaleMinima(6.0, scaleY: 0.0)
//        }
        
        //barChart.zoom(scaleX: 2, scaleY: 0, x: 0, y: 0)
//        barChart.zoom(scaleX: 7, scaleY: 0, x: 0, y: 0)
//        barChart.setScaleMinima(6.0, scaleY: 0.0)
    }
    
    
    
    
    
    @IBAction func backBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

