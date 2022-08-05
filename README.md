# Spring4Shell 攻撃体験キット

## 必要なもの

- Docker （Docker Compose）の動作環境

## 1. サーバーの起動

```
docker-compose up
```

[http://localhost:8080/spring4shell/hello?hello=world](http://localhost:8080/spring4shell/hello?hello=world)

にアクセスすることで、サーバーが正常に起動しているかどうかを確認できます。

## 2. 攻撃コードの実行

ローカルのシェル上で次のコマンドを実行します。

```
bash exploit.bash
```

[http://localhost:8080/shell.jsp?cmd=id](http://localhost:8080/shell.jsp?cmd=id)

のような URL にアクセスすることで、サーバー上で `id` コマンドを実行した結果をレスポンスとして見ることができます。

## 3. JSP ファイルの設置

次のコマンドでコンテナのシェルにアクセスします。

```
docker-compose exec spring4shell /bin/bash
```

コンテナのシェル上で次のコマンドを実行して、 `hoge.jsp` ファイルを作成します。

```
echo '<%= 7*7 %>' > webapps/ROOT/hoge.jsp
```

[http://localhost:8080/hoge.jsp](http://localhost:8080/hoge.jsp)

にアクセスすることで、作成した JSP ファイル内のコード実行結果を見ることができます。

## 参考

### サーバーの終了方法

```
docker-compose down
```

### 今回の脆弱性の仕組み

`HelloController.java` の下記の部分において、リクエストで与えられたパラメータから`HelloModel`型の`hello`に変換をするための処理（Spring Framework の Data Binding と呼ばれる仕組み）が実行されます。

```java
@RequestMapping("/hello")
public String hello(HelloModel hello) {
    return hello.hello;
}
```

この Data Binding では次のような処理を行っています。

まず、`HelloModel` クラスのメソッドを列挙して、**get から始まるメソッド**　と **set から始まるメソッド**にグループ化されます。

この際、Java で宣言するクラスは、全て `Object` から継承されていることに注目します。すると、 `Object` には `getClass` というメソッドも宣言されているため、`HelloModel`には、明示的に書かなくても、この `getClass` も宣言されていることになります。

よって、**get から始まるメソッド** には、この `getClass` も追加され、`HelloModel` のグループ化は以下のようになります。

**get から始まるメソッド**

- getHello
- getWorld
- getClass

**set から始まるメソッド**

- setHello

次に、リクエストのパラメータに `hello=world` と指定してリクエストを送信します。すると、「`hello` というプロパティに `"world"` という文字列を設定する」として解釈されます。

これにより、`HelloWorld` の中の **set から始まるメソッド** から `hello` に値を設定するための `setHello` を呼び出して、Data Binding の処理が実行されます。

さらに、この Data Binding には階層構造を解決する仕組みも備えています。

つまり、`world.message=helloworld` というリクエストを送ることで、「`world` というプロパティを取得」して、取得した中の「`message`というプロパティに `"helloworld"` という文字列を設定する」として解釈されます。

その結果、次の順番でメソッドが呼び出されます。

1. `HelloModel`の`getWorld`
2. `WorldModel`の`setMessage`

このようにして、階層構造になっているプロパティにも値を設定することができます。

次に攻撃のリクエストに指定されているパラメータの 1 つを見てみると、`class.module.classLoader.resources.context.parent.pipeline.first.suffix=.jsp` というクエリパラメータが指定されています。

その結果、次の順番でメソッドが呼び出されます。

1. `HelloModel` の `getClass` （`getClass` は暗黙的に宣言されているもの）
2. 1.で得られたオブジェクトの `getModule`
3. 2.で得られたオブジェクトの `getResources`
4. ...

最終的に得られるオブジェクトがログの出力先を管理するもので、その中のプロパティの一つである `suffix` が書き換えられます。

このように、攻撃のリクエストによって、ログ出力に関連する変数の値が変更されてしまいます。

その結果、ログの出力先や出力内容が変更され、バックドアとなる `shell.jsp` をサーバー側に設置することができてしまうというものでした。

### IntelliJ を使ったサーバー側のコードのデバッグ方法

攻撃体験キット配下のディレクトリで次のコマンドを実行します。

```
make tomcat
```

次に IntelliJ でこのリポジトリをクローンしたディレクトリを開いて、次の手順でデバッガーの起動を構成します。

1. メニューの「実行」→「実行構成の編集」で、＋ボタンをクリックして、「tomcat サーバー」の「リモート」を追加します。
2. 「サーバー」タブの「アプリケーションサーバー」の右にある「構成」をクリック、「Tomcat のホーム」、「Tomcat のベースディレクトリ」の両方に上記でコピーした tomcat ディレクトリを指定します。
3. 「スタートアップ/接続」タブで「デバッグ」を選択、「ポート」に「8000」を指定します。
4. Docker のコンテナを起動した状態で、メニューの「実行」→「デバッグ」から、「Tomcat …」を選択して実行することで、デバッガを起動します。

上記のセットアップが終了すれば、次回以降は 4. の手順のみでデバッグができるようになります。

### 階層構造の解決のデモでブレークポイントを設置する箇所

Class: `org.springframework.beans.AbstractNestablePropertyAccessor`

```java
protected AbstractNestablePropertyAccessor getPropertyAccessorForPropertyPath(String propertyPath)
public void setPropertyValue(PropertyValue pv)
```

Class: `org.springframework.beans.CachedIntrospectionResults `

```
PropertyDescriptor getPropertyDescriptor(String name)
```

### 参考リンク

- [https://spring.io/blog/2022/03/31/spring-framework-rce-early-announcement](https://spring.io/blog/2022/03/31/spring-framework-rce-early-announcement)
- [https://www.lunasec.io/docs/blog/spring-rce-vulnerabilities/](https://www.lunasec.io/docs/blog/spring-rce-vulnerabilities/)
- [https://github.com/reznok/Spring4Shell-POC](https://github.com/reznok/Spring4Shell-POC)
- [https://zenn.dev/kurenaif/articles/b4062cbce45b21](https://zenn.dev/kurenaif/articles/b4062cbce45b21)
