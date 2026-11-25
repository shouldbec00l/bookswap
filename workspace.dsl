workspace "BookSwap" "Сервіс обміну паперовими книгами у межах міста" {

    !identifiers hierarchical

    model {
        user = person "Користувач" "Читач: додає книги, шукає та обмінюється ними"
        moderator = person "Модератор" "Обробляє скарги, блокує порушників"

        emailSystem = softwareSystem "Email-сервіс" "Транзакційні листи (SMTP / Amazon SES)" "External"
        geocoder = softwareSystem "Геокодер" "OpenStreetMap Nominatim: район -> координати" "External"

        bookswap = softwareSystem "BookSwap" "Платформа обміну паперовими книгами в межах міста" {
            spa = container "Web Application" "UI: каталог, пошук, мої книги, заявки" "React, TypeScript (SPA)" "WebApp"
            api = container "Backend API" "Бізнес-логіка, JWT-автентифікація, пошук, заявки. Stateless" "Node.js (NestJS), REST + OpenAPI" "API"
            db = container "Database" "Користувачі, книги, заявки, відгуки, скарги" "PostgreSQL + PostGIS" "Database"
            cache = container "Cache" "Кеш каталогу та пошуку, rate limiting" "Redis" "Cache"
            storage = container "Object Storage" "Фото обкладинок книг" "S3-сумісне сховище" "Storage"
            observability = container "Observability Stack" "Метрики, логи, дашборди, алерти" "Prometheus, Grafana, Loki" "Observability"
        }

        # Контекст
        user -> bookswap "Шукає книги, створює заявки" "HTTPS"
        moderator -> bookswap "Модерує контент" "HTTPS"
        bookswap -> emailSystem "Надсилає сповіщення" "SMTP/HTTPS"
        bookswap -> geocoder "Визначає координати району" "HTTPS/JSON"
        emailSystem -> user "Доставляє листи"

        # Контейнери
        user -> bookswap.spa "Відкриває у браузері" "HTTPS"
        moderator -> bookswap.spa "Відкриває у браузері" "HTTPS"
        bookswap.spa -> bookswap.api "Викликає API" "HTTPS/JSON + JWT"
        bookswap.spa -> bookswap.storage "Завантажує/читає обкладинки (pre-signed URL / CDN)" "HTTPS"
        bookswap.api -> bookswap.db "Читає/пише" "SQL, TCP 5432"
        bookswap.api -> bookswap.cache "Кешує/читає" "RESP, TCP 6379"
        bookswap.api -> bookswap.storage "Видає pre-signed URL, видаляє об'єкти" "S3 API"
        bookswap.api -> emailSystem "Надсилає листи асинхронно" "SMTP/HTTPS"
        bookswap.api -> geocoder "Геокодування району" "HTTPS"
        bookswap.observability -> bookswap.api "Збирає метрики /metrics та логи" "HTTP"

        # Розгортання (4+1: Physical / Deployment view)
        production = deploymentEnvironment "Production" {
            deploymentNode "AWS" "" "Amazon Web Services, eu-central-1" {

                deploymentNode "CloudFront + S3" "Роздача статики SPA" "CDN + Object Storage" {
                    containerInstance bookswap.spa
                }

                deploymentNode "Amazon S3 (covers)" "Бакет обкладинок, versioning, SSE" "Object Storage" {
                    containerInstance bookswap.storage
                }

                deploymentNode "VPC" "" "Amazon VPC" {

                    deploymentNode "Amazon EKS" "Multi-AZ, HPA 2-6 реплік" "Kubernetes" {
                        deploymentNode "api Deployment" "Rolling update" "Kubernetes Deployment" 3 {
                            containerInstance bookswap.api
                        }
                        deploymentNode "monitoring namespace" "" "Kubernetes Namespace" {
                            containerInstance bookswap.observability
                        }
                    }

                    deploymentNode "Amazon RDS" "Multi-AZ, PITR-бекапи" "PostgreSQL 16 + PostGIS" {
                        containerInstance bookswap.db
                    }

                    deploymentNode "Amazon ElastiCache" "Primary + replica" "Redis 7" {
                        containerInstance bookswap.cache
                    }
                }
            }
        }
    }

    views {
        systemContext bookswap "SystemContext" "Діаграма контексту системи BookSwap" {
            include *
            autoLayout lr
        }

        container bookswap "Containers" "Діаграма контейнерів BookSwap" {
            include *
            autoLayout lr
        }

        deployment bookswap "Production" "ProductionDeployment" "Розгортання BookSwap у AWS" {
            include *
            autoLayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "WebApp" {
                shape WebBrowser
            }
            element "Database" {
                shape Cylinder
            }
            element "Cache" {
                shape Cylinder
                background #d9534f
            }
            element "Storage" {
                shape Folder
                background #f0ad4e
            }
            element "Observability" {
                background #5cb85c
            }
        }

        theme default
    }
}