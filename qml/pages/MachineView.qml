import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0

Page {
    id: page

    property var container // container object from dbus

    function is_started(){
        // get Boolean for status: on = true, everything else = false
        if (container.container_status === "RUNNING"){
            return true
        } else {
            return false
        }
    }
    function is_frozen(){
        // get Boolean for status: frozen = true, everything else = false
        if (container.container_status === "FROZEN"){
            return true
        } else {
            return false
        }
    }

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            id: pullDownMenu

            MenuItem {
                text: "Settings"
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("MachineSettings.qml"), {container : container} )
                }
            }
            MenuItem {
                text: "Snapshot"
                enabled: false
            }
            MenuItem {
                text: is_frozen() ? "Unfreeze" : "Freeze"
                enabled: is_frozen() ? true : is_started()
                onClicked: {
                    if (is_frozen()){
                        daemon.call("unfreeze_container",[container.container_name], function (result) {
                            if (result){
                                // update model
                                container.container_status = "RUNNING"
                            }
                        })
                    }else{
                        daemon.call("freeze_container",[container.container_name], function (result) {
                            if (result){
                                // update model
                                container.container_status = "FROZEN"
                            }
                        })
                    }
                }
            }
            MenuItem {
                text: is_started() ? "Stop" : "Start"
                enabled: is_frozen() ? false : true
                onClicked: {
                    if (is_started()){
                        daemon.call("stop_container",[container.container_name], function (result) {
                            if (result){
                                // update model
                                container.container_status = "STOPPED"
                            }
                        })
                    }else {
                        daemon.call("start_container",[container.container_name], function (result) {
                            if (result){
                                // update model
                                container.container_status = "RUNNING"
                            }
                        })
                    }
                }
            }
        }

        Column {
            spacing: Theme.paddingLarge
            width: parent.width
            height: parent.height

            PageHeader {
                   id: pageHeader

                Rectangle {
                    anchors.fill: parent
                    color: Theme._wallpaperOverlayColor

                    PageHeader {
                        title: qsTr("Container: ") + container.container_name
                    }
                }
            }

            SilicaGridView {
                id: gridView
                width: parent.width //- Theme.paddingLarge
                height: parent.height - pageHeader.height
                clip: true
                cellWidth: page.isLandscape ? parent.width/1.5 : parent.width - Theme.paddingLarge
                cellHeight: contentHeight //column.height //page.height *2
                onContentHeightChanged: cellHeight = contentHeight

                VerticalScrollDecorator {}

                model: ListModel {
                    id:listmodel

                    ListElement{}

                }

                delegate: Column {
                    id: column
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: page.isLandscape ? parent.width/1.5 : parent.width - Theme.paddingLarge
                    spacing: Theme.paddingLarge

                    IconButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: icon.width //+ Theme.paddingLarge //GridView.view.width
                        height: icon.height - Theme.paddingLarge - Theme.paddingLarge

                        icon.source: "image://theme/icon-m-computer"
                        icon.width: Theme.itemSizeExtraLarge + Theme.itemSizeSmall //GridView.view.width
                        icon.height: Theme.itemSizeExtraLarge + Theme.itemSizeSmall

                    }


                    SectionHeader{
                        text: "details"
                    }
                    Row {

                        width: parent.width

                        Column {
                            Label {
                                text: "<b>name: </b>" + container.container_name
                            }
                            Label{
                                text: "<b>state: </b>" + container.container_status
                            }
                            Label{
                                //  rootfs label, long string
                                text: "<b>rootfs: </b>" + container.container_rootfs
                            }
                            Label{
                                //  rootfs label, long string
                                text: "<b>pid: </b>" + container.container_pid
                            }
                            Label {
                                text: "<b>cpu use: </b>" + container.container_cpu
                            }
                            Label{
                                text: "<b>memory use: </b>" + container.container_mem
                            }
                            Label{
                                text: "<b>kmem use: </b>" + container.container_kmem
                            }
                        }
                    }

                    SectionHeader {
                        text: "session"
                    }

                    ButtonLayout {
                        enabled: is_started()

                        Button {
                            text: "attach"
                            enabled: false
                        }
                        Button {
                            text: "X session"
                            enabled: is_started() ? true : false
                            onClicked: {
                                daemon.call("start_xsession",[container.container_name], function (result) {
                                    if (result){
                                    // Desktop started
                                    }
                                });
                            }
                        }
                    }

                    SectionHeader{
                        text: "mountpoints"
                    }
                    Row {
                        width: parent.width

                        Column {
                            id: columnMountpoints
                            Repeater{
                                model: ListModel { id: listmodelrepeater}
                                Component.onCompleted: {
                                    var ind = 0
                                    for (var mp in container.container_mounts){
                                        //console.log(container.container_mounts[mp])
                                        listmodelrepeater.set(ind, {"mount_point":container.container_mounts[mp]})
                                        ind++

                                    }
                                    gridView.cellHeight += column.height
                                }

                                Label {
                                    text: mount_point
                                    Component.onCompleted: gridView.cellHeight += Theme.paddingLarge*1.6
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Item {
        DBusInterface {
            id: daemon

            bus: DBus.SystemBus
            service: 'org.sailfishcontainers.daemon'
            iface: 'org.sailfishcontainers.daemon'
            path: '/org/sailfishcontainers/daemon'
        }
    }
}
