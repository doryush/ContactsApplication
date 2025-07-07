//
//  ViewController.swift
//  ContactsApplication
//
//  Created by Doryush Normatov on 7/3/25.
//

import UIKit
import Contacts

class ViewController: UIViewController, UITableViewDataSource {
    
    private var sections: [Section] = []
    private let tableView = UITableView()
    
    private let emptyLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "😕 Контактов нет"
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.font = .systemFont(ofSize: 18, weight: .medium)
        return lbl
    }()
    
    private let viewModel = ContactViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGreen
        setupTableView()
        
        // Показываем сразу placeholder, пока не пришла ни одна секция
        tableView.backgroundView = emptyLabel
        
        bindViewModel()
        viewModel.load()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = rc
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    private func bindViewModel() {
        viewModel.onUpdate = { [weak self] newSections in
            guard let self = self else { return }
            self.sections = newSections
            self.tableView.reloadData()
            self.tableView.backgroundView = newSections.flatMap { $0.contacts }.isEmpty
                ? self.emptyLabel
                : nil
            self.tableView.refreshControl?.endRefreshing()
        }
        
        viewModel.onPermissionDenied = { [weak self] in
            guard let self = self else { return }
            self.emptyLabel.text = "🚫 Нет доступа к контактам.\nРазрешите доступ в Настройках"
            self.tableView.backgroundView = self.emptyLabel
            self.tableView.refreshControl?.endRefreshing()
        }
        
        viewModel.onError = { [weak self] error in
            guard let self = self else { return }
            self.emptyLabel.text = "❗️ Ошибка: \(error.localizedDescription)"
            self.tableView.backgroundView = self.emptyLabel
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        sections.map { $0.letter }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].letter
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let contact = sections[indexPath.section].contacts[indexPath.row]
        let cell    = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.numberOfLines = 0
        if contact.extraPhonesCount > 0 {
            cell.textLabel?.text = "\(contact.name)\n\(contact.phone) и ещё \(contact.extraPhonesCount) номер(а)"
        } else {
            cell.textLabel?.text = "\(contact.name)\n\(contact.phone)"
        }
        
        return cell
    }
    
    // MARK: - Actions
    
    @objc private func handleRefresh() {
        viewModel.refresh()
    }
}
