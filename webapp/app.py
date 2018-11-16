from flask import Flask, jsonify, request
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session
from sqlalchemy import create_engine
import requests


from sqlalchemy import create_engine, MetaData, Table, Column, String
from sqlalchemy.orm import mapper, sessionmaker
 

class ISG_Installed_Software(object):
     pass
    
class ISG_AssetFailures(object):
    pass

class ISG_Assets(object):
    pass

class ISG_Disks(object):
    pass
 
#----------------------------------------------------------------------
def loadSession():
    """"""    
    dbPath = 'places.sqlite'
    engine = create_engine('mssql+pyodbc://sel-dbs-11.synseal.com:1433/isg_AssetMgmt?driver=SQL+Server+Native+Client+11.0', echo=True)
 
    metadata = MetaData(engine)
    isg_assets = Table('ISG_Assets', metadata, autoload=True)
    isg_installed_software = Table('ISG_Installed_Software', metadata, autoload=True)
    isg_assetfailures = Table('ISG_AssetFailures', metadata, autoload=True)
    isg_disks = Table('ISG_Disks', metadata, autoload=True)
    mapper(ISG_Assets, isg_assets)
    mapper(ISG_Installed_Software, isg_installed_software)
    mapper(ISG_AssetFailures, isg_assetfailures)
    mapper(ISG_Disks, isg_disks)
 
    Session = sessionmaker(bind=engine)
    session = Session()
    return session

session = loadSession()
res = session.query(ISG_Assets).all()
for i in res:
    print(i.Hostname, i.MaxClockSpeed)


app = Flask(__name__)

@app.route('/assets', methods=['GET'])
def get_all_assets():
    """
    returns all assets in json format
    """
    results = session.query(ISG_Assets).all()
    results_json = []
    for asset in results:
        new_asset = {}
        new_asset['Hostname'] = asset.Hostname.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['IPAddress'] = asset.IPAddress.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['MACAddress'] = asset.MACAddress.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['host_id'] = asset.host_id
        new_asset['OS'] = asset.OS.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['Manufacturer'] = asset.Manufacturer.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['Model'] = asset.Model.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['MemoryCapacity'] = asset.MemoryCapacity.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['MaxClockSpeed'] = asset.MaxClockSpeed.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['LogicalCoreCount'] = asset.LogicalCoreCount.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['ProcessorModel'] = asset.ProcessorModel.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['SerialNumber'] = asset.SerialNumber.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['IsLaptop'] = asset.IsLaptop.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['Last_Updated'] = asset.Last_Updated
        new_asset['SPVersion'] = asset.SPVersion.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['User'] = asset.User.replace('\r', '').replace('\n', ' ').rstrip()
        results_json.append(new_asset)
    return jsonify(results_json)


@app.route('/assets/<asset_name>', methods=['GET'])
def get_asset_information(asset_name):
    """
    gets asset information and returns json
    data
    """
    results = session.query(ISG_Assets).filter_by(Hostname = asset_name).all()
    results_json = []
    for asset in results:
        new_asset = {}
        new_asset['Hostname'] = asset.Hostname.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['IPAddress'] = asset.IPAddress.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['MACAddress'] = asset.MACAddress.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['host_id'] = asset.host_id
        new_asset['OS'] = asset.OS.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['Manufacturer'] = asset.Manufacturer.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['Model'] = asset.Model.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['MemoryCapacity'] = asset.MemoryCapacity.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['MaxClockSpeed'] = asset.MaxClockSpeed.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['LogicalCoreCount'] = asset.LogicalCoreCount.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['ProcessorModel'] = asset.ProcessorModel.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['SerialNumber'] = asset.SerialNumber.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['IsLaptop'] = asset.IsLaptop.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['Last_Updated'] = asset.Last_Updated
        new_asset['SPVersion'] = asset.SPVersion.replace('\r', '').replace('\n', ' ').rstrip()
        new_asset['User'] = asset.User.replace('\r', '').replace('\n', ' ').rstrip()
        results_json.append(new_asset)
    return jsonify(results_json)

@app.route('/assets/<asset_name>/software')
def asset_software(asset_name):
    """
    gets all installed software for an asset
    and returns json formatted data
    """
    results = session.query(ISG_Installed_Software).filter_by(Hostname = asset_name).all()
    results_json = []
    for product in results:
        software = {}
        software['Hostname'] = product.Hostname.replace('\r', '').replace('\n', ' ').rstrip()
        software['DisplayName'] = product.DisplayName.replace('\r', '').replace('\n', ' ').rstrip()
        software['DisplayVersion'] = product.DisplayVersion.replace('\r', '').replace('\n', ' ').rstrip()
        software['Publisher'] = product.Publisher.replace('\r', '').replace('\n', ' ').rstrip()
        software['software_id'] = product.software_id
        results_json.append(software)
    return jsonify(results_json)

@app.route('/assets/search')
def asset_search():
    if request.args.get('user'):
        results_json = []
        results = session.query(ISG_Assets).filter_by(User = request.args.get('user')).all()
        if results:
            print(results[0].__dir__())
            print(request.args.get('user'))
            for asset in results:
                new_asset = {}
                new_asset['Hostname'] = asset.Hostname.replace('\r', '').replace('\n', ' ').rstrip()
                new_asset['IPAddress'] = asset.IPAddress.replace('\r', '').replace('\n', ' ').rstrip()
                new_asset['MACAddress'] = asset.MACAddress.replace('\r', '').replace('\n', ' ').rstrip()
                new_asset['host_id'] = asset.host_id
                new_asset['OS'] = asset.OS.replace('\r', '').replace('\n', ' ').rstrip()
                new_asset['Manufacturer'] = asset.Manufacturer.replace('\r', '').replace('\n', ' ').rstrip()
                new_asset['Model'] = asset.Model.replace('\r', '').replace('\n', ' ').rstrip()
                new_asset['MemoryCapacity'] = asset.MemoryCapacity.replace('\r', '').replace('\n', ' ').rstrip()
                new_asset['MaxClockSpeed'] = asset.MaxClockSpeed.replace('\r', '').replace('\n', ' ').rstrip()
                new_asset['LogicalCoreCount'] = asset.LogicalCoreCount.replace('\r', '').replace('\n', ' ').rstrip()
                new_asset['ProcessorModel'] = asset.ProcessorModel.replace('\r', '').replace('\n', ' ').rstrip()
                new_asset['SerialNumber'] = asset.SerialNumber.replace('\r', '').replace('\n', ' ').rstrip()
                new_asset['IsLaptop'] = asset.IsLaptop.replace('\r', '').replace('\n', ' ').rstrip()
                new_asset['Last_Updated'] = asset.Last_Updated
                new_asset['SPVersion'] = asset.SPVersion.replace('\r', '').replace('\n', ' ').rstrip()
                new_asset['User'] = asset.User.replace('\r', '').replace('\n', ' ').rstrip()
                results_json.append(new_asset)
        return jsonify(results_json)
    return "need search itme"

@app.route('/assets/stats', methods=['GET'])
def get_asset_stats():
    """
    get some basic stats on the assets and return it
    """
    results_json = {}
    results_json['Asset Count'] = len(session.query(ISG_Assets).all())
    results_json['Asset Count without usernames'] = len(session.query(ISG_Assets).filter_by(User = '').all())
    return jsonify(results_json)


@app.route('/assets/<asset_name>/disks', methods=['GET'])
def get_asset_disks(asset_name):
    """
    gets all disk information for the asset
    """
    results = session.query(ISG_Disks).filter_by(Hostname = asset_name).all()
    results_json = []
    for disk in results:
        disk_info = {}
        disk_info['Hostname'] = disk.Hostname.rstrip()
        disk_info['Caption'] = disk.Caption.rstrip()
        disk_info['DeviceID'] = disk.DeviceID.rstrip()
        disk_info['FileSystem'] = disk.FileSystem.rstrip()
        disk_info['FreeSpace'] = disk.FreeSpace.rstrip()
        disk_info['Name'] = disk.Name.rstrip()
        disk_info['Size'] = disk.Size.rstrip()
        disk_info['Status'] = disk.Status.rstrip()
        disk_info['VolumeName'] = disk.VolumeName.rstrip()
        disk_info['VolumeSerialNumber'] = disk.VolumeSerialNumber.rstrip()
        """disk_info['DisplayName'] = disk.DisplayName.replace('\r', '').replace('\n', ' ').rstrip()
        disk_info['DisplayVersion'] = disk.DisplayVersion.replace('\r', '').replace('\n', ' ').rstrip()
        disk_info['Publisher'] = disk.Publisher.replace('\r', '').replace('\n', ' ').rstrip()
        disk_info['software_id'] = disk.software_id"""
        results_json.append(disk_info)
    return jsonify(results_json)

@app.route('/assets/failures', methods=['GET'])
def get_asset_failures():
    """
    gets all asset failures and returns json data
    """
    results = session.query(ISG_AssetFailures).all()
    asset_features = []
    for asset_failure in results:
        asset_fail = {}
        asset_fail['ComputerName'] = asset_failure.ComputerName
        asset_features.append(asset_fail)
    return jsonify(asset_features)

app.run('0.0.0.0', port=5000, debug=True)