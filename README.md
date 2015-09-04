# vagrant-virtuoso

[VagrantとVirtuosoでローカル用のSPARQLエンドポイントをつくる](https://github.com/lodac/lodac/wiki/VagrantとVirtuosoでローカル用のSPARQLエンドポイントをつくる)のうち、Virtuosoの起動までをChefで自動化するCookbookです。

上記ドキュメントの作業に加え、VirtuosoをUbuntu Linuxのサービスとして登録しています。したがって、例えばホストOSを再起動してもVirtuosoが自動的に立ち上がります。

## 必要なもの

- [Vagrant](https://www.vagrantup.com)
- [ChefDk](https://downloads.chef.io/chef-dk/)
- [VirtualBox](https://www.virtualbox.org)
- [vagrant-omnibus](https://github.com/chef/vagrant-omnibus)
- [vagrant-berkshelf](https://github.com/berkshelf/vagrant-berkshelf)

vagrant-omnibus, vagrant-berkshelfは下記のようにインストールできます。
Vagrant, ChefDkをインストールした後、下記を実行してください。

```shell
% chef exec vagrant plugin install vagrant-omnibus vagrant-berkshelf
```

## 起動方法

```shell
% git clone https://github.com/kunishi/vagrant-virtuoso.git
% cd vagrant-virtuoso
% chef exec vagrant up
```
