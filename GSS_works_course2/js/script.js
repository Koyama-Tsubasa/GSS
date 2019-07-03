var bookDataFromLocalStorage = [];

/* kendoWindow */
$(function() {

    var myWindow = $("#window"),
        button = $("#add-button");

    /* 讓按了 [ 新增書籍 ] 之後才跑出小視窗 */
    button.click(function() {
        myWindow.data("kendoWindow").center().open();
    });

    /* 關閉小視窗 */
    function onClose() {
        myWindow.kendoWindow().data("kendoWindow").close();
    };

    /* 讓輸入的地方空掉 */
    function cLear() {
        $("#book_name").val("");
        $("#book_author").val("");
    };

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

    var validator = $("#window").kendoValidator().data("kendoValidator");

    function MAXID() {
        var maxid = 0;
        for (var x in bookDataFromLocalStorage) {
            if (bookDataFromLocalStorage[x].BookId > maxid){
                maxid = bookDataFromLocalStorage[x].BookId;
            }
        }
        return ++maxid;
    }

    /* 新增書籍 */
    function addBook() {

        /* 檢查 input 裡有沒有輸入資料 */
        if (validator.validate()) {

            var newBC = $("#book_category").data("kendoDropDownList").text();
            var newBN = $("#book_name").val();
            var newBA = $("#book_author").val();
            var newBD = $("#bought_datepicker").data("kendoDatePicker").value();
            var Ndata = {
                "BookId":MAXID(),
                "BookCategory":newBC,
                "BookName":newBN,
                "BookAuthor":newBA,
                "BookBoughtDate":newBD,
                "BookPublisher":"None"
            }

            /* 讓使用者再次確認新增書籍的資料對不對 */
            if (confirm("Do you really want to add this book?\n"+
                        "書籍種類: " + newBC +
                        "\n書籍名稱: " + newBN +
                        "\n作者: " + newBA +
                        "\n購買日期: " + newBD)) {

                /* 新增到下面 datasource 裡 */
                var dataArray = $("#book_grid").data("kendoGrid").dataSource;
                dataArray.add(Ndata);

                /* 新增 ( push ) 到localstorage 裡 */
                bookDataFromLocalStorage.push(Ndata);
                localStorage.setItem("bookData",JSON.stringify(bookDataFromLocalStorage));

            }

        }

    };

    /* 繼續新增書籍 */
    $("#btn-conadd-book").click(function(){
        addBook();
        cLear();
    });

    /* 新增書籍並關閉小視窗 */
    $("#btn-addclose-book").click(function(){
        addBook();
        if (validator.validate()) {
            cLear();
            onClose();
        }
    });

});

$(function(){

    loadBookData();

    var data = [
        {text:"資料庫",value:"database"},
        {text:"網際網路",value:"internet"},
        {text:"應用系統整合",value:"system"},
        {text:"家庭保健",value:"home"},
        {text:"語言",value:"language"}
    ];

    $("#book_category").kendoDropDownList({
        dataTextField: "text",
        dataValueField: "value",
        dataSource: data,
        index: 0,
        change: onChange
    });
    
    /* 讓原本的日期調成 yyyy-mm-dd 形式, 並改成只能輸入有效的日期 */
    $("#bought_datepicker").kendoDatePicker({
        value: new Date(),
        dateInput: true,
        format: "yyyy-MM-dd"
    });

    $("#book_grid").kendoGrid({
        dataSource: {
            data: bookDataFromLocalStorage,
            schema: {
                model: {
                    fields: {
                        BookId: { type:"int" },
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
    $(".book-grid-search").on("input",function(){
        $(".book-grid-search").filter(function(){
            /* 搜尋資料時的條件 */
            $("#book_grid").data("kendoGrid").dataSource.filter({
                logic: "or" ,   // 只要有相關字就好
                filters:[
                    { field: "BookId" , operator: "eq" , value: $(this).val() },
                    /* 因為 BookId 是 int 值, 無法用 contains -> 用 eq 讓只有一樣 id 才可以搜尋的到 */
                    { field: "BookName" , operator: "contains" , value: $(this).val() },
                    { field: "BookCategory" , operator: "contains" , value: $(this).val() },
                    { field: "BookAuthor" , operator: "contains" , value: $(this).val() },
                    { field: "BookBoughtDate" , operator: "contains" , value: $(this).val() }
                ]
            });

        });

    });

});

function loadBookData(){
    bookDataFromLocalStorage = JSON.parse(localStorage.getItem("bookData"));
    if(bookDataFromLocalStorage == null){
        bookDataFromLocalStorage = bookData;
        localStorage.setItem("bookData",JSON.stringify(bookDataFromLocalStorage));
    }
};

/* 變更圖片 */
function onChange(){
    var value = this.value();
    $(".book-image").attr("src","image/"+value+".jpg");
};

/* 刪除書籍 */
function deleteBook(event){

    var dataItem = this.dataItem($(event.target).closest("tr"));    // 找離案的刪除建最近的 row
    if (confirm('Do you really want to delete this record?')) {
    var dataArray = $("#book_grid").data("kendoGrid").dataSource;
    var deletId = dataArray.indexOf(dataItem);     // 找這個 row 在現在 localstorage 的哪一個 id 位置

    /* 從下面 datasource 刪除 */
    dataArray.remove(dataItem);

    /* 從 localstorage 裡刪除 */
    bookDataFromLocalStorage.splice(deletId,1);
    localStorage.setItem("bookData",JSON.stringify(bookDataFromLocalStorage));

    }
};