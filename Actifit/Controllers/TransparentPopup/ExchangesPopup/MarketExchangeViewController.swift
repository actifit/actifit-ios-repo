//
//  MarketExchangeViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 31/08/2023.
//

import UIKit
import SafariServices
class MarketExchangeViewController: UIViewController {
    
    @IBOutlet weak var backgroundLayerView: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    var exchangeListItem: [ExchangeMarketModel] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        getAfitMarker()
        setUI()
    }
    
    private func setUI() {
        backgroundLayerView.layer.cornerRadius = 10
        backgroundLayerView.clipsToBounds = true
        
        tableView.separatorStyle = .none
    }
    
    static func create() -> MarketExchangeViewController {
        let vc = UIStoryboard(name: "MarketExchangePopup", bundle: nil).instantiateViewController(withIdentifier: "MarketExchangeViewController") as! MarketExchangeViewController
        vc.modalPresentationStyle = .overFullScreen
        return vc
    }
    
    private func getAfitMarker() {
        API().getMarketExchangesAPI { info, statusCode in
            if let response = info as? String {
                let data = response.utf8Data()
                let decoder = JSONDecoder()
                do {
                    self.exchangeListItem = try decoder.decode([ExchangeMarketModel].self, from: data)
                    print(self.exchangeListItem)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                   
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        } failure: { error in
            
        }

    }
    
    @IBAction func closeBtnTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    
}

extension MarketExchangeViewController: UITableViewDelegate , UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exchangeListItem.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = exchangeListItem[indexPath.row].exchange
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemLink = exchangeListItem[indexPath.row].link
        let url = URL(string: itemLink ?? "")
        present(SFSafariViewController(url: url!), animated: true)
    }
    
    
}
