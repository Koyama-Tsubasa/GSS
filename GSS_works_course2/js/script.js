var bookDataFromLocalStorage = [];
var addData = 1;

/* kendoWindow */
$(function() {

    var myWindow = $("#window"),
        button = $("#add-button");

    button.click(function() {
        myWindow.data("kendoWindow").center().open();
    });

    function onClose() {
        myWindow.kendoWindow().data("kendoWindow").close();
    }

    myWindow.kendoWindow({
        width: "400px",
        height: "540px",
        title: "新增書籍",
        visible: false,
        actions: [
            "Pin",
            "Minimize",
            "Maximize",
            "Close"
        ],
        close: onClose
    }).data("kendoWindow");

    var validator = $(".detail").kendoValidator().data("kendoValidator");

    /* 新增書籍 */
    $(".btn-add-book").click(function(){

        if (validator.validate()) {

            var newBC = $("#book_category").data("kendoDropDownList").text();
            var newBN = $("#book_name").val();
            var newBA = $("#book_author").val();
            var newBD = $("#bought_datepicker").val();
            var Ndata = {
                "BookId":bookDataFromLocalStorage.length + addData,
                "BookCategory":newBC,
                "BookName":newBN,
                "BookAuthor":newBA,
                "BookBoughtDate":newBD,
                "BookPublisher":"None"
            };

            var dataSource = $("#book_grid").data("kendoGrid").dataSource;
            dataSource.add(Ndata);
            dataSource.sync();

            bookDataFromLocalStorage.push(Ndata);
            localStorage.setItem("bookData",JSON.stringify(bookDataFromLocalStorage));
            loadBookData();

            onClose();

        }

    })

});

$(function(){
    loadBookData();
    var data = [
        {text:"資料庫",value:"database"},
        {text:"網際網路",value:"internet"},
        {text:"應用系統整合",value:"system"},
        {text:"家庭保健",value:"home"},
        {text:"語言",value:"language"}
    ]
    $("#book_category").kendoDropDownList({
        dataTextField: "text",
        dataValueField: "value",
        dataSource: data,
        index: 0,
        change: onChange
    });
    $("#bought_datepicker").kendoDatePicker({
        value: new Date(),
        format: "yyyy-mm-dd"
    });
    $("#book_grid").kendoGrid({
        dataSource: {
            data: bookDataFromLocalStorage,
            schema: {
                model: {
                    fields: {
                        BookId: {type:"int" },
                        BookName: { type: "string" },
                        BookCategory: { type: "string" },
                        BookAuthor: { type: "string" },
                        BookBoughtDate: { type: "string" }
                    }
                }
            },
            pageSize: 20,
        },
        toolbar: kendo.template("<div class='book-grid-toolbar'><input class='book-grid-search' placeholder='我想要找......' type='text'></input></div>"),
        height: 550,
        sortable: true,
        pageable: {
            input: true,
            numeric: false
        },
        columns: [
            { field: "BookId", title: "書籍編號",width:"10%"},
            { field: "BookName", title: "書籍名稱", width: "50%" },
            { field: "BookCategory", title: "書籍種類", width: "10%" },
            { field: "BookAuthor", title: "作者", width: "15%" },
            { field: "BookBoughtDate", title: "購買日期", width: "15%" },
            { command: { text: "刪除", click: deleteBook }, title: " ", width: "120px" }
        ]
        
    });

    /* 搜尋書籍 */
    $(".book-grid-toolbar").on("input",function(){
        $(".book-grid-search").filter(function(){

            $("#book_grid").data("kendoGrid").dataSource.filter({
                logic: "or" ,
                filters:[
                    { field: "BookId" , operator: "eq" , value: $(this).val() },
                    { field: "BookName" , operator: "contains" , value: $(this).val() },
                    { field: "BookCategory" , operator: "contains" , value: $(this).val() },
                    { field: "BookAuthor" , operator: "contains" , value: $(this).val() },
                    { field: "BookBoughtDate" , operator: "contains" , value: $(this).val() }
                ]
            })

        })

    });

})

function loadBookData(){
    bookDataFromLocalStorage = JSON.parse(localStorage.getItem("bookData"));
    if(bookDataFromLocalStorage == null){
        bookDataFromLocalStorage = bookData;
        localStorage.setItem("bookData",JSON.stringify(bookDataFromLocalStorage));
    }
}

/* 變更圖片 */
function onChange(){
    var value = this.value();
    $(".book-image").attr("src","image/"+value+".jpg")
}

/* 刪除書籍 */
function deleteBook(){

    event.preventDefault();
    var dataItem = this.dataItem($(event.target).closest("tr"));
    if (confirm('Do you really want to delete this record?')) {
    var dataSource = $("#book_grid").data("kendoGrid").dataSource;
    var del = dataSource.indexOf(dataItem);

    dataSource.remove(dataItem);
    dataSource.sync();

    bookDataFromLocalStorage.splice(del,1);
    localStorage.setItem("bookData",JSON.stringify(bookDataFromLocalStorage));
    loadBookData();

    addData++;

    }
}