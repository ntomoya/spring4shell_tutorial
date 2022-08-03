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

### IntelliJ を使ったサーバー側のコードのデバッグ方法

攻撃体験キット配下のディレクトリで次のコマンドを実行します。

```
make tomcat
```

次に IntelliJ で体験キットのディレクトリを開いて、次の手順でデバッガーの起動を構成します。

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
