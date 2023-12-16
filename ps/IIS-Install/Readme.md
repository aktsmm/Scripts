# Web-Serverとその管理ツールを含む機能をインストールし、既存のIISのデフォルトページを削除して、新しいコンテンツを追加しています

このPowerShellコードは、Windows ServerでIIS（Internet Information Services）をインストールし、それに関連する設定を行っています。具体的には、Web-Serverとその管理ツールを含む機能をインストールし、既存のIISのデフォルトページを削除して、新しいコンテンツを追加しています。
GUIでIISをインストールするのめんどくさいと思うので。そういった時に。


# 以下はコードの要点
1. Install-WindowsFeature -name Web-Server -IncludeManagementTools: Web-Serverとその管理ツールを含む機能をインストールします。
2. $iisstart_path = Join-Path $Env:SystemDrive "inetpub\wwwroot\iisstart.htm": $iisstart_path変数に、IISのデフォルトページのパスを設定します。
3. Remove-Item $iisstart_path: 既存のIISのデフォルトページ（iisstart.htm）を削除します。
4. Add-Content -Path $iisstart_path -Value $("Hi, this is " + $Env:ComputerName): 新しいコンテンツとして、「Hi, this is [コンピュータの名前]」というメッセージを含むiisstart.htmファイルを作成します。
このコードを実行すると、IISがインストールされ、デフォルトのウェブページが指定されたメッセージに変更されます。ただし、十分な権限が必要であることに注意してください。また、このコードはPowerShellであるため、PowerShellスクリプトとして実行されることを想定しています。
